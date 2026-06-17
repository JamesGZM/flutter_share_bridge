import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import * as wxOpenSdk from '@tencent/wechat_open_sdk';

const WECHAT_THUMB_MAX_BYTES = 64 * 1024;
const CALLBACK_TIMEOUT_MS = 120 * 1000;

interface ImageSource {
  type: string;
  path?: string;
  bytes?: Uint8Array;
  mimeType?: string;
}

export default class ShareBridgeWechatPlugin implements FlutterPlugin, MethodCallHandler {
  private static activePlugin: ShareBridgeWechatPlugin | null = null;
  private static pendingWant: Want | null = null;

  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;
  private wxApi: wxOpenSdk.WXApi | null = null;
  private pendingResult: MethodResult | null = null;
  private pendingRequestId: string | null = null;
  private readonly eventHandler: wxOpenSdk.WXApiEventHandler = {
    onReq: (_req: wxOpenSdk.BaseReq): void => {},
    onResp: (resp: wxOpenSdk.BaseResp): void => {
      this.handleShareResp(resp);
    },
  };

  static handleWant(want: Want): boolean {
    const handled = ShareBridgeWechatPlugin.activePlugin?.handleWant(want) ?? false;
    if (!handled) {
      ShareBridgeWechatPlugin.pendingWant = want;
    }
    return handled;
  }

  getUniqueClassName(): string {
    return 'ShareBridgeWechatPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'share_bridge_wechat');
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext();
    ShareBridgeWechatPlugin.activePlugin = this;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.context = null;
    this.wxApi = null;
    this.pendingResult = null;
    this.pendingRequestId = null;
    if (ShareBridgeWechatPlugin.activePlugin === this) {
      ShareBridgeWechatPlugin.activePlugin = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'initialize') {
      this.initialize(call, result);
    } else if (call.method === 'isInstalled') {
      result.success(this.wxApi?.isWXAppInstalled() ?? false);
    } else if (call.method === 'supports') {
      result.success(this.supports(call));
    } else if (call.method === 'shareWebPage') {
      this.shareWebPage(call, result);
    } else if (call.method === 'shareImage') {
      this.shareImage(call, result);
    } else {
      result.notImplemented();
    }
  }

  private initialize(call: MethodCall, result: MethodResult): void {
    const appId = call.argument('appId') as string | null;
    if (!appId || appId.trim().length === 0) {
      result.error('configError', 'WeChat appId must not be empty.', null);
      return;
    }
    this.wxApi = wxOpenSdk.WXAPIFactory.createWXAPI(appId);
    this.consumePendingWant();
    result.success(null);
  }

  private supports(call: MethodCall): boolean {
    const channel = call.argument('channel') as string | null;
    const contentType = call.argument('contentType') as string | null;
    return (channel === 'wechat.session' || channel === 'wechat.timeline') &&
      (contentType === 'webpage' || contentType === 'image');
  }

  private shareWebPage(call: MethodCall, result: MethodResult): void {
    const title = call.argument('title') as string | null;
    const description = call.argument('description') as string | null;
    const url = call.argument('url') as string | null;
    if (!title || !description || !url) {
      result.success(this.resultMap('invalidArgument', 'title, description, and url must not be empty.'));
      return;
    }

    const webpageObject = new wxOpenSdk.WXWebpageObject();
    webpageObject.webpageUrl = url;

    const mediaMessage = new wxOpenSdk.WXMediaMessage();
    mediaMessage.mediaObject = webpageObject;
    mediaMessage.title = title;
    mediaMessage.description = description;

    const thumbnail = this.imageSource(call, 'thumbnail');
    const thumbnailData = this.thumbnailData(thumbnail);
    if (thumbnailData) {
      mediaMessage.thumbData = thumbnailData;
    }

    this.sendMessage(call, result, mediaMessage);
  }

  private shareImage(call: MethodCall, result: MethodResult): void {
    const image = this.imageSource(call, 'image');
    if (!image) {
      result.success(this.resultMap('invalidArgument', 'image must be a file path or non-empty bytes.'));
      return;
    }

    const imageObject = new wxOpenSdk.WXImageObject();
    if (image.bytes) {
      imageObject.imageData = this.bytesToString(image.bytes);
    } else {
      imageObject.uri = fileUri.getUriFromPath(image.path ?? '');
    }

    const mediaMessage = new wxOpenSdk.WXMediaMessage();
    mediaMessage.mediaObject = imageObject;
    const thumbnail = this.imageSource(call, 'thumbnail');
    const thumbnailData = this.thumbnailData(thumbnail);
    if (thumbnailData) {
      mediaMessage.thumbData = thumbnailData;
    } else if (image.bytes) {
      mediaMessage.thumbData = image.bytes;
    }

    this.sendMessage(call, result, mediaMessage);
  }

  private async sendMessage(
    call: MethodCall,
    result: MethodResult,
    message: wxOpenSdk.WXMediaMessage,
  ): Promise<void> {
    const api = this.wxApi;
    if (!api) {
      result.success(this.resultMap('sdkNotInitialized', 'WeChat HarmonyOS SDK is not initialized.'));
      return;
    }
    if (!api.isWXAppInstalled()) {
      result.success(this.resultMap('appNotInstalled', 'WeChat is not installed.'));
      return;
    }
    if (this.pendingResult != null) {
      result.success(this.resultMap('busy', 'A WeChat share request is already pending.'));
      return;
    }
    const context = this.context as common.UIAbilityContext | null;
    if (!context) {
      result.success(this.resultMap('nativeError', 'HarmonyOS ability context is unavailable.'));
      return;
    }

    const channel = call.argument('channel') as string | null;
    const requestId = call.argument('requestId') as string | null;
    const req = new wxOpenSdk.SendMessageToWXReq();
    req.scene = this.sceneForChannel(channel);
    req.message = message;
    req.transaction = requestId ?? `${Date.now()}`;

    try {
      const sent = await api.sendReq(context, req);
      if (sent === false) {
        result.success(this.resultMap('nativeError', 'WeChat sendReq returned false.'));
        return;
      }
      this.pendingResult = result;
      this.pendingRequestId = req.transaction ?? null;
      this.scheduleTimeout(this.pendingRequestId);
    } catch (error) {
      result.success(this.resultMap('nativeError', `${error}`));
    }
  }

  private handleWant(want: Want): boolean {
    const api = this.wxApi;
    if (!api) {
      return false;
    }
    return api.handleWant(want, this.eventHandler);
  }

  private handleShareResp(resp: wxOpenSdk.BaseResp): void {
    const result = this.pendingResult;
    if (!result) {
      return;
    }
    if (this.pendingRequestId && resp.transaction && resp.transaction !== this.pendingRequestId) {
      return;
    }
    this.pendingResult = null;
    this.pendingRequestId = null;
    switch (resp.errCode) {
      case wxOpenSdk.ErrCode.ERR_OK:
        result.success(this.resultMap('success', resp.errStr ?? null));
        return;
      case wxOpenSdk.ErrCode.ERR_USER_CANCEL:
        result.success(this.resultMap('cancelled', resp.errStr ?? null));
        return;
      case wxOpenSdk.ErrCode.ERR_UNSUPPORTED:
        result.success(this.resultMap('unsupportedContent', resp.errStr ?? null));
        return;
      case wxOpenSdk.ErrCode.ERR_AUTH_DENIED:
      case wxOpenSdk.ErrCode.ERR_BAN:
        result.success(this.resultMap('permissionDenied', resp.errStr ?? null));
        return;
      default:
        result.success(this.resultMap('nativeError', resp.errStr ?? null));
    }
  }

  private consumePendingWant(): void {
    const want = ShareBridgeWechatPlugin.pendingWant;
    if (!want) {
      return;
    }
    if (this.handleWant(want)) {
      ShareBridgeWechatPlugin.pendingWant = null;
    }
  }

  private scheduleTimeout(requestId: string | null): void {
    if (!requestId) {
      return;
    }
    setTimeout(() => {
      if (this.pendingRequestId === requestId && this.pendingResult != null) {
        this.completePending(this.resultMap('timeout', 'Timed out waiting for WeChat callback.'));
      }
    }, CALLBACK_TIMEOUT_MS);
  }

  private completePending(value: Record<string, Object | null>): void {
    const result = this.pendingResult;
    this.pendingResult = null;
    this.pendingRequestId = null;
    result?.success(value);
  }

  private sceneForChannel(channel: string | null): number {
    if (channel === 'wechat.timeline') {
      return wxOpenSdk.SendMessageToWXReq.WXSceneTimeline;
    }
    return wxOpenSdk.SendMessageToWXReq.WXSceneSession;
  }

  private imageSource(call: MethodCall, key: string): ImageSource | null {
    const source = call.argument(key) as ImageSource | null;
    if (!source) {
      return null;
    }
    if (source.type === 'file' && source.path && source.path.length > 0) {
      return source;
    }
    if (source.type === 'memory' && source.bytes && source.bytes.length > 0) {
      return source;
    }
    return null;
  }

  private thumbnailData(source: ImageSource | null): Uint8Array | undefined {
    if (!source) {
      return undefined;
    }
    if (source.bytes) {
      return source.bytes;
    }
    if (source.path) {
      return this.readThumbnailFile(source.path);
    }
    return undefined;
  }

  private readThumbnailFile(path: string): Uint8Array | undefined {
    try {
      const stat = fs.statSync(path);
      if (stat.size <= 0 || stat.size > WECHAT_THUMB_MAX_BYTES) {
        return undefined;
      }
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      try {
        const buffer = new ArrayBuffer(stat.size);
        const readSize = fs.readSync(file.fd, buffer);
        if (readSize <= 0) {
          return undefined;
        }
        return new Uint8Array(buffer, 0, readSize);
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
      return undefined;
    }
  }

  private bytesToString(bytes: Uint8Array): string {
    let value = '';
    for (let index = 0; index < bytes.length; index++) {
      value += String.fromCharCode(bytes[index]);
    }
    return value;
  }

  private resultMap(code: string, message: string | null): Record<string, Object | null> {
    return {
      'code': code,
      'message': message,
    };
  }
}

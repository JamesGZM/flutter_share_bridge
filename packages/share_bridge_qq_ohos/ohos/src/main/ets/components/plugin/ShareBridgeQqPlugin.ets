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
import {
  IQQOpenApi,
  OpenApiConfig,
  QQOpenApiFactory,
  ShareData,
  ShareResult,
} from '@tencent/qq-open-sdk';

export default class ShareBridgeQqPlugin implements FlutterPlugin, MethodCallHandler {
  private static activePlugin: ShareBridgeQqPlugin | null = null;
  private static pendingWant: Want | null = null;

  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;
  private qqApi: IQQOpenApi | null = null;

  static handleWant(want: Want): boolean {
    if (!ShareBridgeQqPlugin.isQqCallbackWant(want)) {
      return false;
    }
    const handled = ShareBridgeQqPlugin.activePlugin?.handleWant(want) ?? false;
    if (!handled) {
      ShareBridgeQqPlugin.pendingWant = want;
    }
    return handled;
  }

  private static isQqCallbackWant(want: Want): boolean {
    const uri = want.uri ?? '';
    return uri.includes('qqopenapi');
  }

  getUniqueClassName(): string {
    return 'ShareBridgeQqPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'share_bridge_qq');
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext();
    ShareBridgeQqPlugin.activePlugin = this;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.context = null;
    this.qqApi = null;
    if (ShareBridgeQqPlugin.activePlugin === this) {
      ShareBridgeQqPlugin.activePlugin = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'initialize') {
      this.initialize(call, result);
    } else if (call.method === 'isInstalled') {
      result.success(this.qqApi?.isQQInstalled() ?? false);
    } else if (call.method === 'supports') {
      result.success(this.supports(call));
    } else if (call.method === 'supportsHarmonySignedShare') {
      result.success(true);
    } else if (call.method === 'shareHarmonySigned') {
      this.shareHarmonySigned(call, result);
    } else {
      result.notImplemented();
    }
  }

  private initialize(call: MethodCall, result: MethodResult): void {
    const appId = call.argument('appId') as string | null;
    if (!appId || appId.trim().length === 0) {
      result.error('configError', 'QQ appId must not be empty.', null);
      return;
    }
    const numericAppId = Number(appId);
    if (!Number.isInteger(numericAppId) || numericAppId <= 0) {
      result.error('configError', 'QQ appId must be a numeric string.', null);
      return;
    }
    const openApiConfig: OpenApiConfig = {
      forceEnableWeb: false,
    };
    this.qqApi = QQOpenApiFactory.createApi(numericAppId, openApiConfig);
    this.consumePendingWant();
    result.success(null);
  }

  private handleWant(want: Want): boolean {
    const api = this.qqApi;
    if (!api) {
      return false;
    }
    api.handleResult(want);
    return true;
  }

  private consumePendingWant(): void {
    const want = ShareBridgeQqPlugin.pendingWant;
    if (!want) {
      return;
    }
    if (this.handleWant(want)) {
      ShareBridgeQqPlugin.pendingWant = null;
    }
  }

  private supports(call: MethodCall): boolean {
    const channel = call.argument('channel') as string | null;
    const contentType = call.argument('contentType') as string | null;
    if (channel === 'qq.qzone' && contentType === 'image') {
      return false;
    }
    return (channel === 'qq.friend' || channel === 'qq.qzone') &&
      (contentType === 'webpage' || contentType === 'image');
  }

  private shareHarmonySigned(call: MethodCall, result: MethodResult): void {
    const api = this.qqApi;
    if (!api) {
      result.success(this.resultMap('sdkNotInitialized', 'QQ HarmonyOS SDK is not initialized.'));
      return;
    }
    if (!api.isQQInstalled()) {
      result.success(this.resultMap('appNotInstalled', 'QQ is not installed.'));
      return;
    }

    const type = call.argument('type') as number | null;
    const shareJson = call.argument('shareJson') as Record<string, Object> | null;
    const timestamp = Number(call.argument('timestamp') as string | null);
    const nonce = Number(call.argument('nonce') as string | null);
    const shareJsonSign = call.argument('shareJsonSign') as string | null;
    const openId = call.argument('openId') as string | undefined;

    if (!type ||
      !shareJson ||
      !Number.isFinite(timestamp) ||
      !Number.isFinite(nonce) ||
      !shareJsonSign) {
      result.success(this.resultMap('invalidArgument', 'QQ HarmonyOS signed share data is incomplete.'));
      return;
    }

    const shareData = new ShareData();
    shareData.shareJson = JSON.stringify(shareJson);
    shareData.timestamp = timestamp;
    shareData.nonce = nonce;
    shareData.shareJsonSign = shareJsonSign;

    api.share(type, shareData, openId)
      .then((shareResult: ShareResult) => {
        result.success(this.mapShareResult(shareResult));
      })
      .catch((error: Error) => {
        result.success(this.resultMap('nativeError', error.message));
      });
  }

  private mapShareResult(result: ShareResult): Record<string, Object | null> {
    const resultType = result.resultType?.toString() ?? '';
    if (resultType.includes('Success')) {
      return this.resultMap('success', result.message ?? null);
    }
    if (resultType.includes('Cancel')) {
      return this.resultMap('cancelled', result.message ?? null);
    }
    return this.resultMap('nativeError', result.message ?? null);
  }

  private resultMap(code: string, message: string | null): Record<string, Object | null> {
    return {
      'code': code,
      'message': message,
    };
  }
}

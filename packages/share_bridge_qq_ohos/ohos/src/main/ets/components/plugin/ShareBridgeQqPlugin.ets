import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import {
  IQQOpenApi,
  QQOpenApiFactory,
  ShareData,
  ShareResult,
} from '@tencent/qq-open-sdk';

export default class ShareBridgeQqPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;
  private qqApi: IQQOpenApi | null = null;

  getUniqueClassName(): string {
    return 'ShareBridgeQqPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'share_bridge_qq');
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.context = null;
    this.qqApi = null;
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
    this.qqApi = QQOpenApiFactory.createApi(numericAppId);
    result.success(null);
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

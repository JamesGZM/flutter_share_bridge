import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_core/share_bridge_core.dart';

import 'share_bridge_wechat_method_channel.dart';

abstract class ShareBridgeWechatPlatform extends PlatformInterface {
  ShareBridgeWechatPlatform() : super(token: _token);

  static final Object _token = Object();

  static ShareBridgeWechatPlatform _instance = MethodChannelShareBridgeWechat();

  static ShareBridgeWechatPlatform get instance => _instance;

  static set instance(ShareBridgeWechatPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({
    required String appId,
    String? universalLink,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<bool> isInstalled() {
    throw UnimplementedError('isInstalled() has not been implemented.');
  }

  Future<ShareResult> shareWebPage({
    required String requestId,
    required ShareChannel channel,
    required ShareWebPageContent content,
  }) {
    throw UnimplementedError('shareWebPage() has not been implemented.');
  }

  Future<ShareResult> shareImage({
    required String requestId,
    required ShareChannel channel,
    required ShareImageContent content,
  }) {
    throw UnimplementedError('shareImage() has not been implemented.');
  }
}

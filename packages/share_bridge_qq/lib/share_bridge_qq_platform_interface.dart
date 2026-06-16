import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_core/share_bridge_core.dart';

import 'share_bridge_qq_method_channel.dart';

abstract class ShareBridgeQqPlatform extends PlatformInterface {
  ShareBridgeQqPlatform() : super(token: _token);

  static final Object _token = Object();

  static ShareBridgeQqPlatform _instance = MethodChannelShareBridgeQq();

  static ShareBridgeQqPlatform get instance => _instance;

  static set instance(ShareBridgeQqPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({
    required String appId,
    String? universalLink,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<bool> isInstalled({
    ShareChannel? channel,
  }) {
    throw UnimplementedError('isInstalled() has not been implemented.');
  }

  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) {
    throw UnimplementedError('supports() has not been implemented.');
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

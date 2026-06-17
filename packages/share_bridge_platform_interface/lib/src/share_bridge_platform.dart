import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_core/share_bridge_core.dart';

abstract class ShareBridgePlatform extends PlatformInterface {
  ShareBridgePlatform() : super(token: _token);

  static final Object _token = Object();
  static final Map<ShareClient, ShareBridgePlatform> _instances = {};

  static ShareBridgePlatform instanceFor(ShareClient client) {
    return _instances[client] ?? _UnregisteredShareBridgePlatform(client);
  }

  static void register({
    required ShareClient client,
    required ShareBridgePlatform instance,
  }) {
    PlatformInterface.verifyToken(instance, _token);
    _instances[client] = instance;
  }

  Future<void> initialize({required String appId, String? universalLink}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<bool> isInstalled() {
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

final class _UnregisteredShareBridgePlatform extends ShareBridgePlatform {
  _UnregisteredShareBridgePlatform(this.client);

  final ShareClient client;

  Never _missingPlugin() {
    throw StateError(
      'No ${client.id} share platform implementation has been registered.',
    );
  }

  @override
  Future<void> initialize({required String appId, String? universalLink}) {
    _missingPlugin();
  }

  @override
  Future<bool> isInstalled() {
    _missingPlugin();
  }

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) {
    _missingPlugin();
  }

  @override
  Future<ShareResult> shareWebPage({
    required String requestId,
    required ShareChannel channel,
    required ShareWebPageContent content,
  }) {
    _missingPlugin();
  }

  @override
  Future<ShareResult> shareImage({
    required String requestId,
    required ShareChannel channel,
    required ShareImageContent content,
  }) {
    _missingPlugin();
  }
}

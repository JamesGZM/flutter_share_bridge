import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_core/share_bridge_core.dart';

/// Base class for platform-specific share implementations.
abstract class ShareBridgePlatform extends PlatformInterface {
  /// Creates a platform implementation instance.
  ShareBridgePlatform() : super(token: _token);

  static final Object _token = Object();
  static final Map<ShareClient, ShareBridgePlatform> _instances = {};

  /// Returns the registered implementation for [client].
  static ShareBridgePlatform instanceFor(ShareClient client) {
    return _instances[client] ?? _UnregisteredShareBridgePlatform(client);
  }

  /// Registers [instance] as the implementation for [client].
  static void register({
    required ShareClient client,
    required ShareBridgePlatform instance,
  }) {
    PlatformInterface.verifyToken(instance, _token);
    _instances[client] = instance;
  }

  /// Initializes the native SDK with host configuration.
  Future<void> initialize({required String appId, String? universalLink}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Returns whether the native client app is installed.
  Future<bool> isInstalled() {
    throw UnimplementedError('isInstalled() has not been implemented.');
  }

  /// Returns whether the native layer supports [content] for [channel].
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) {
    throw UnimplementedError('supports() has not been implemented.');
  }

  /// Shares a webpage payload.
  Future<ShareResult> shareWebPage({
    required String requestId,
    required ShareChannel channel,
    required ShareWebPageContent content,
  }) {
    throw UnimplementedError('shareWebPage() has not been implemented.');
  }

  /// Shares an image payload.
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

library;

import 'package:flutter/services.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

export 'package:share_bridge_core/share_bridge_core.dart';

/// Share-only QQ/QZone provider.
final class QqShareProvider implements ShareProvider {
  QqShareProvider({
    required this.appId,
    this.universalLink,
    ShareBridgePlatform? platform,
  }) : _platform = platform ?? ShareBridgePlatform.instanceFor(ShareClient.qq);

  static Future<void> setPrivacyGranted(bool granted) {
    final platform = ShareBridgePlatform.instanceFor(ShareClient.qq);
    if (platform is ShareBridgePrivacyControl) {
      return (platform as ShareBridgePrivacyControl).setPrivacyGranted(granted);
    }
    throw StateError(
      'The registered QQ platform implementation does not support '
      'privacy control.',
    );
  }

  final String appId;
  final String? universalLink;
  final ShareBridgePlatform _platform;

  bool _isInitialized = false;
  bool _isSharing = false;

  @override
  String get providerId => 'qq';

  @override
  ShareClient get client => ShareClient.qq;

  @override
  Set<ShareChannel> get supportedChannels => {
        ShareChannel.qqFriend,
        ShareChannel.qzone,
      };

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    if (appId.trim().isEmpty) {
      throw const ShareBridgeException(
        ShareResultCode.configError,
        'QQ appId must not be empty.',
      );
    }

    try {
      await _platform.initialize(
        appId: appId,
        universalLink: universalLink,
      );
    } on PlatformException catch (error) {
      throw ShareBridgeException(
        ShareResultCode.values.firstWhere(
          (item) => item.name == error.code,
          orElse: () => ShareResultCode.nativeError,
        ),
        error.message ?? 'QQ SDK initialization failed.',
        cause: error,
      );
    }
    _isInitialized = true;
  }

  @override
  Future<bool> isClientInstalled() {
    return _platform.isInstalled();
  }

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    if (!supportedChannels.contains(channel)) {
      return false;
    }
    return _platform.supports(channel: channel, content: content);
  }

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    if (_isSharing) {
      return const ShareResult(
        code: ShareResultCode.busy,
        message: 'A QQ share request is already pending.',
      );
    }
    _isSharing = true;
    try {
      final requestId = _newRequestId();
      return switch (content) {
        ShareWebPageContent() => _platform.shareWebPage(
            requestId: requestId,
            channel: channel,
            content: content,
          ),
        ShareImageContent() => _platform.shareImage(
            requestId: requestId,
            channel: channel,
            content: content,
          ),
      };
    } finally {
      _isSharing = false;
    }
  }

  String _newRequestId() {
    return 'qq-${DateTime.now().microsecondsSinceEpoch}';
  }
}

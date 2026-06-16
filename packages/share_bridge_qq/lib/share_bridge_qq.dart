library;

import 'package:share_bridge_core/share_bridge_core.dart';

import 'share_bridge_qq_platform_interface.dart';

export 'package:share_bridge_core/share_bridge_core.dart';

/// Share-only QQ/QZone provider.
final class QqShareProvider implements ShareProvider {
  QqShareProvider({
    required this.appId,
    this.universalLink,
    ShareBridgeQqPlatform? platform,
  }) : _platform = platform ?? ShareBridgeQqPlatform.instance;

  static bool _privacyGranted = false;

  static void setPrivacyGranted(bool granted) {
    _privacyGranted = granted;
  }

  final String appId;
  final String? universalLink;
  final ShareBridgeQqPlatform _platform;

  bool _isInitialized = false;
  bool _isSharing = false;

  @override
  String get providerId => 'qq';

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
    if (!_privacyGranted) {
      throw const ShareBridgeException(
        ShareResultCode.permissionDenied,
        'Privacy permission has not been granted.',
      );
    }
    if (appId.trim().isEmpty) {
      throw const ShareBridgeException(
        ShareResultCode.configError,
        'QQ appId must not be empty.',
      );
    }

    await _platform.initialize(
      appId: appId,
      universalLink: universalLink,
      privacyGranted: _privacyGranted,
    );
    _isInitialized = true;
  }

  @override
  Future<bool> isInstalled({ShareChannel? channel}) {
    return _platform.isInstalled(channel: channel);
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
    if (!await isInstalled(channel: channel)) {
      return const ShareResult(
        code: ShareResultCode.appNotInstalled,
        message: 'QQ is not installed.',
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

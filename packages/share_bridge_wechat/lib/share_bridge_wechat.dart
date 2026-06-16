library;

import 'package:share_bridge_core/share_bridge_core.dart';

import 'share_bridge_wechat_platform_interface.dart';

export 'package:share_bridge_core/share_bridge_core.dart';

/// Share-only WeChat provider.
final class WechatShareProvider implements ShareProvider {
  WechatShareProvider({
    required this.appId,
    this.universalLink,
    ShareBridgeWechatPlatform? platform,
  }) : _platform = platform ?? ShareBridgeWechatPlatform.instance;

  static bool _privacyGranted = false;

  static Future<void> setPrivacyGranted(bool granted) async {
    _privacyGranted = granted;
  }

  final String appId;
  final String? universalLink;
  final ShareBridgeWechatPlatform _platform;

  bool _isInitialized = false;
  bool _isSharing = false;

  @override
  String get providerId => 'wechat';

  @override
  Set<ShareChannel> get supportedChannels => {
        ShareChannel.wechatSession,
        ShareChannel.wechatTimeline,
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
        'WeChat appId must not be empty.',
      );
    }

    await _platform.initialize(
      appId: appId,
      universalLink: universalLink,
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
    return supportedChannels.contains(channel) &&
        (content is ShareWebPageContent || content is ShareImageContent);
  }

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    if (_isSharing) {
      return const ShareResult(
        code: ShareResultCode.busy,
        message: 'A WeChat share request is already pending.',
      );
    }
    if (!await isInstalled(channel: channel)) {
      return const ShareResult(
        code: ShareResultCode.appNotInstalled,
        message: 'WeChat is not installed.',
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
    return 'wechat-${DateTime.now().microsecondsSinceEpoch}';
  }
}

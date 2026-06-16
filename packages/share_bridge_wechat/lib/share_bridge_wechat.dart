library;

import 'package:flutter/services.dart';
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

  final String appId;
  final String? universalLink;
  final ShareBridgeWechatPlatform _platform;

  bool _isInitialized = false;
  bool _isSharing = false;

  @override
  String get providerId => 'wechat';

  @override
  ShareClient get client => ShareClient.wechat;

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
    if (appId.trim().isEmpty) {
      throw const ShareBridgeException(
        ShareResultCode.configError,
        'WeChat appId must not be empty.',
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
        error.message ?? 'WeChat SDK initialization failed.',
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

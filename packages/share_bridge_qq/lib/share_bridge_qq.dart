library;

import 'package:flutter/services.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

export 'package:share_bridge_core/share_bridge_core.dart';

typedef QqHarmonyShareSigner = Future<QqHarmonyShareSignature> Function(
  QqHarmonyShareSignatureRequest request,
);

final class QqHarmonyShareSignatureRequest {
  const QqHarmonyShareSignatureRequest({
    required this.channel,
    required this.content,
    required this.type,
    required this.shareJson,
  });

  final ShareChannel channel;
  final ShareContent content;
  final int type;
  final Map<String, Object?> shareJson;
}

final class QqHarmonyShareSignature {
  const QqHarmonyShareSignature({
    required this.type,
    required this.shareJson,
    required this.timestamp,
    required this.nonce,
    required this.shareJsonSign,
    this.openId,
  });

  final int type;
  final Map<String, Object?> shareJson;
  final String timestamp;
  final String nonce;
  final String shareJsonSign;
  final String? openId;

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'shareJson': shareJson,
      'timestamp': timestamp,
      'nonce': nonce,
      'shareJsonSign': shareJsonSign,
      if (openId != null) 'openId': openId,
    };
  }
}

/// Share-only QQ/QZone provider.
final class QqShareProvider implements ShareProvider {
  QqShareProvider({
    required this.appId,
    this.universalLink,
    QqHarmonyShareSigner? qqHarmonySigner,
    ShareBridgePlatform? platform,
  })  : _qqHarmonySigner = qqHarmonySigner,
        _platform = platform ?? ShareBridgePlatform.instanceFor(ShareClient.qq);

  static Future<void> setPrivacyGranted(bool granted) {
    return _qqMethodChannel.invokeMethod<void>('setPrivacyGranted', {
      'granted': granted,
    });
  }

  final String appId;
  final String? universalLink;
  final QqHarmonyShareSigner? _qqHarmonySigner;
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
      if (await _supportsHarmonySignedShare()) {
        return _shareHarmony(
          requestId: requestId,
          channel: channel,
          content: content,
        );
      }
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

  Future<ShareResult> _shareHarmony({
    required String requestId,
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    final request = _harmonySignatureRequest(
      channel: channel,
      content: content,
    );
    if (request == null) {
      return const ShareResult(
        code: ShareResultCode.unsupportedContent,
        message: 'This QQ HarmonyOS share content is not supported.',
      );
    }

    final signer = _qqHarmonySigner;
    if (signer == null) {
      return const ShareResult(
        code: ShareResultCode.unsupportedContent,
        message: 'QQ HarmonyOS sharing requires qqHarmonySigner.',
      );
    }

    try {
      final signature = await signer(request);
      final validationError = _validateHarmonySignature(signature);
      if (validationError != null) {
        return validationError;
      }
      final raw = await _qqMethodChannel.invokeMapMethod<String, Object?>(
        'shareHarmonySigned',
        {
          'requestId': requestId,
          'channel': channel.id,
          ...signature.toMap(),
        },
      );
      return _resultFromMap(raw);
    } on ShareBridgeException catch (error) {
      return ShareResult(
        code: error.code,
        message: error.message,
        raw: error.cause,
      );
    } catch (error) {
      return ShareResult(
        code: ShareResultCode.nativeError,
        message: 'QQ HarmonyOS share signing failed.',
        raw: error,
      );
    }
  }

  QqHarmonyShareSignatureRequest? _harmonySignatureRequest({
    required ShareChannel channel,
    required ShareContent content,
  }) {
    return switch ((channel, content)) {
      (
        ShareChannel.qqFriend,
        ShareWebPageContent(
          :final title,
          :final description,
          :final url,
          :final thumbnail,
        ),
      ) =>
        QqHarmonyShareSignatureRequest(
          channel: channel,
          content: content,
          type: 2,
          shareJson: {
            'msg_style': 0,
            'title': title,
            'summary': description,
            'brief': 'Share Bridge',
            'url': url,
            if (thumbnail case ShareFileImageSource(:final path))
              'picture_url': path,
          },
        ),
      (
        ShareChannel.qqFriend,
        ShareImageContent(image: ShareFileImageSource(:final path)),
      ) =>
        QqHarmonyShareSignatureRequest(
          channel: channel,
          content: content,
          type: 2,
          shareJson: {
            'msg_style': 6,
            'share_uris': [path],
          },
        ),
      (
        ShareChannel.qzone,
        ShareWebPageContent(
          :final title,
          :final description,
          :final url,
          :final thumbnail,
        ),
      ) =>
        QqHarmonyShareSignatureRequest(
          channel: channel,
          content: content,
          type: 3009,
          shareJson: {
            'title': title,
            'summary': description,
            'targetUrl': url,
            if (thumbnail case ShareFileImageSource(:final path))
              'imageUrls': [path],
          },
        ),
      _ => null,
    };
  }

  ShareResult? _validateHarmonySignature(QqHarmonyShareSignature signature) {
    if (signature.type <= 0 ||
        signature.shareJson.isEmpty ||
        signature.timestamp.trim().isEmpty ||
        signature.nonce.trim().isEmpty ||
        signature.shareJsonSign.trim().isEmpty) {
      return const ShareResult(
        code: ShareResultCode.invalidArgument,
        message: 'QQ HarmonyOS signed share data is incomplete.',
      );
    }
    return null;
  }

  String _newRequestId() {
    return 'qq-${DateTime.now().microsecondsSinceEpoch}';
  }
}

const MethodChannel _qqMethodChannel = MethodChannel('share_bridge_qq');

Future<bool> _supportsHarmonySignedShare() async {
  try {
    return await _qqMethodChannel.invokeMethod<bool>(
          'supportsHarmonySignedShare',
        ) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

ShareResult _resultFromMap(Map<String, Object?>? raw) {
  if (raw == null) {
    return const ShareResult(code: ShareResultCode.unknown);
  }
  final codeName = raw['code'] as String?;
  final code = ShareResultCode.values.firstWhere(
    (item) => item.name == codeName,
    orElse: () => ShareResultCode.unknown,
  );
  return ShareResult(
    code: code,
    message: raw['message'] as String?,
    raw: raw,
  );
}

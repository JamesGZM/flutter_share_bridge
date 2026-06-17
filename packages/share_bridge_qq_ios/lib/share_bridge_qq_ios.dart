library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

/// iOS implementation for QQ and QZone sharing.
final class ShareBridgeQqIOS extends ShareBridgePlatform {
  static void registerWith() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: ShareBridgeQqIOS(),
    );
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('share_bridge_qq');

  @override
  Future<void> initialize({
    required String appId,
    String? universalLink,
  }) async {
    await methodChannel.invokeMethod<void>('initialize', {
      'appId': appId,
      'universalLink': universalLink,
    });
  }

  @override
  Future<bool> isInstalled() async {
    return await methodChannel.invokeMethod<bool>('isInstalled') ?? false;
  }

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    return await methodChannel.invokeMethod<bool>('supports', {
          'channel': channel.id,
          'contentType': switch (content) {
            ShareWebPageContent() => 'webpage',
            ShareImageContent() => 'image',
          },
        }) ??
        false;
  }

  @override
  Future<ShareResult> shareWebPage({
    required String requestId,
    required ShareChannel channel,
    required ShareWebPageContent content,
  }) async {
    final raw = await methodChannel.invokeMapMethod<String, Object?>(
      'shareWebPage',
      {
        'requestId': requestId,
        'channel': channel.id,
        'title': content.title,
        'description': content.description,
        'url': content.url,
        'thumbnail': _imageSourceToMap(content.thumbnail),
      },
    );
    return _resultFromMap(raw);
  }

  @override
  Future<ShareResult> shareImage({
    required String requestId,
    required ShareChannel channel,
    required ShareImageContent content,
  }) async {
    final raw = await methodChannel.invokeMapMethod<String, Object?>(
      'shareImage',
      {
        'requestId': requestId,
        'channel': channel.id,
        'image': _imageSourceToMap(content.image),
        'thumbnail': _imageSourceToMap(content.thumbnail),
      },
    );
    return _resultFromMap(raw);
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

Map<String, Object?>? _imageSourceToMap(ShareImageSource? source) {
  return switch (source) {
    null => null,
    ShareFileImageSource(:final path) => {
        'type': 'file',
        'path': path,
      },
    ShareMemoryImageSource(:final bytes, :final mimeType) => {
        'type': 'memory',
        'bytes': bytes,
        'mimeType': mimeType,
      },
  };
}

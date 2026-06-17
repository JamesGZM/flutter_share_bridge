/// HarmonyOS MethodChannel implementation for QQ and QZone sharing.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

/// HarmonyOS implementation for QQ and QZone sharing.
final class ShareBridgeQqOhos extends ShareBridgePlatform {
  /// Registers this implementation for the QQ client.
  static void registerWith() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: ShareBridgeQqOhos(),
    );
  }

  /// MethodChannel used by the HarmonyOS implementation.
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
    if (channel == ShareChannel.qzone && content is ShareImageContent) {
      return false;
    }
    if (content is! ShareWebPageContent && content is! ShareImageContent) {
      return false;
    }
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
    return const ShareResult(
      code: ShareResultCode.unsupportedContent,
      message: 'QQ HarmonyOS webpage sharing requires qqHarmonySigner.',
    );
  }

  @override
  Future<ShareResult> shareImage({
    required String requestId,
    required ShareChannel channel,
    required ShareImageContent content,
  }) async {
    return const ShareResult(
      code: ShareResultCode.unsupportedContent,
      message: 'QQ HarmonyOS image sharing requires qqHarmonySigner.',
    );
  }
}

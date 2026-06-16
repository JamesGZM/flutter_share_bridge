/// A share destination such as WeChat session, WeChat timeline, QQ friend, or
/// QZone.
///
/// This is intentionally a value object instead of an enum so that future
/// packages can add channels without changing `share_bridge_core`.
final class ShareChannel {
  const ShareChannel(this.id);

  static const wechatSession = ShareChannel('wechat.session');
  static const wechatTimeline = ShareChannel('wechat.timeline');
  static const qqFriend = ShareChannel('qq.friend');
  static const qzone = ShareChannel('qq.qzone');

  final String id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ShareChannel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Base class for all supported share payloads.
sealed class ShareContent {
  const ShareContent();

  const factory ShareContent.image({
    required String imagePath,
    String? thumbPath,
  }) = ShareImageContent;

  const factory ShareContent.webpage({
    required String title,
    required String description,
    required String url,
    String? thumbPath,
  }) = ShareWebPageContent;
}

/// Image share payload.
final class ShareImageContent extends ShareContent {
  const ShareImageContent({
    required this.imagePath,
    this.thumbPath,
  });

  final String imagePath;
  final String? thumbPath;
}

/// Web page share payload.
final class ShareWebPageContent extends ShareContent {
  const ShareWebPageContent({
    required this.title,
    required this.description,
    required this.url,
    this.thumbPath,
  });

  final String title;
  final String description;
  final String url;
  final String? thumbPath;
}

/// Normalized result returned by every share provider.
final class ShareResult {
  const ShareResult({
    required this.code,
    this.message,
    this.raw,
  });

  final ShareResultCode code;
  final String? message;
  final Object? raw;

  bool get isSuccess => code == ShareResultCode.success;
  bool get isCancelled => code == ShareResultCode.cancelled;
}

/// Cross-provider result codes.
enum ShareResultCode {
  success,
  cancelled,
  failed,
  unsupportedChannel,
  unsupportedContent,
  appNotInstalled,
  sdkNotInitialized,
  invalidArgument,
  configError,
  permissionDenied,
  nativeError,
  timeout,
  busy,
  unknown,
}

/// Platform-specific share implementation contract.
abstract interface class ShareProvider {
  String get providerId;

  Set<ShareChannel> get supportedChannels;

  bool get isInitialized;

  Future<void> initialize();

  Future<bool> isInstalled({
    ShareChannel? channel,
  });

  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  });

  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  });
}

/// Registry and dispatcher for share providers.
final class ShareManager {
  final List<ShareProvider> _providers = <ShareProvider>[];

  Future<void> register(ShareProvider provider) async {
    _providers.removeWhere((item) => item.providerId == provider.providerId);
    _providers.add(provider);
  }

  Set<ShareChannel> get registeredChannels {
    return {
      for (final provider in _providers) ...provider.supportedChannels,
    };
  }

  Future<void> initializeAll() async {
    for (final provider in _providers) {
      if (!provider.isInitialized) {
        await provider.initialize();
      }
    }
  }

  Future<bool> isInstalled({
    required ShareChannel channel,
  }) async {
    final provider = _findProvider(channel);
    if (provider == null) {
      return false;
    }
    return provider.isInstalled(channel: channel);
  }

  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    final validationError = _validate(content);
    if (validationError != null) {
      return validationError;
    }

    final provider = _findProvider(channel);
    if (provider == null) {
      return const ShareResult(
        code: ShareResultCode.unsupportedChannel,
        message: 'No provider registered for this channel.',
      );
    }

    if (!provider.isInitialized) {
      try {
        await provider.initialize();
      } on ShareBridgeException catch (error) {
        return ShareResult(
          code: error.code,
          message: error.message,
          raw: error.cause,
        );
      } catch (error) {
        return ShareResult(
          code: ShareResultCode.nativeError,
          message: 'Provider initialization failed.',
          raw: error,
        );
      }
    }

    final supported = await provider.supports(
      channel: channel,
      content: content,
    );
    if (!supported) {
      return const ShareResult(
        code: ShareResultCode.unsupportedContent,
        message: 'This provider does not support the content.',
      );
    }

    return provider.share(channel: channel, content: content);
  }

  ShareProvider? _findProvider(ShareChannel channel) {
    for (final provider in _providers) {
      if (provider.supportedChannels.contains(channel)) {
        return provider;
      }
    }
    return null;
  }

  ShareResult? _validate(ShareContent content) {
    return switch (content) {
      ShareImageContent(:final imagePath) when imagePath.trim().isEmpty =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'imagePath must not be empty.',
        ),
      ShareWebPageContent(
        :final title,
        :final description,
        :final url,
      )
          when title.trim().isEmpty ||
              description.trim().isEmpty ||
              url.trim().isEmpty =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'title, description, and url must not be empty.',
        ),
      ShareWebPageContent(:final url)
          when Uri.tryParse(url)?.hasScheme != true =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'url must be an absolute URI.',
        ),
      _ => null,
    };
  }
}

/// Exception type for provider initialization and argument validation errors.
final class ShareBridgeException implements Exception {
  const ShareBridgeException(
    this.code,
    this.message, {
    this.cause,
  });

  final ShareResultCode code;
  final String message;
  final Object? cause;

  @override
  String toString() {
    return 'ShareBridgeException($code, $message)';
  }
}

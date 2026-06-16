import 'dart:typed_data';

/// A concrete client app such as WeChat or QQ.
///
/// This is a value object so future packages can add clients without changing
/// `share_bridge_core`.
final class ShareClient {
  const ShareClient(this.id);

  static const wechat = ShareClient('wechat');
  static const qq = ShareClient('qq');

  final String id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ShareClient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// A share destination such as WeChat session, WeChat timeline, QQ friend, or
/// QZone.
///
/// This is intentionally a value object instead of an enum so that future
/// packages can add channels without changing `share_bridge_core`.
final class ShareChannel {
  const ShareChannel({
    required this.id,
    required this.client,
  });

  static const wechatSession = ShareChannel(
    id: 'wechat.session',
    client: ShareClient.wechat,
  );
  static const wechatTimeline = ShareChannel(
    id: 'wechat.timeline',
    client: ShareClient.wechat,
  );
  static const qqFriend = ShareChannel(
    id: 'qq.friend',
    client: ShareClient.qq,
  );
  static const qzone = ShareChannel(
    id: 'qq.qzone',
    client: ShareClient.qq,
  );

  final String id;
  final ShareClient client;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ShareChannel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Local image input supported by share providers.
sealed class ShareImageSource {
  const ShareImageSource();

  const factory ShareImageSource.file(String path) = ShareFileImageSource;

  const factory ShareImageSource.memory(
    Uint8List bytes, {
    String? mimeType,
  }) = ShareMemoryImageSource;
}

/// Image data already available as a readable local file.
final class ShareFileImageSource extends ShareImageSource {
  const ShareFileImageSource(this.path);

  final String path;
}

/// Image data already loaded in memory.
final class ShareMemoryImageSource extends ShareImageSource {
  const ShareMemoryImageSource(
    this.bytes, {
    this.mimeType,
  });

  final Uint8List bytes;
  final String? mimeType;
}

/// Base class for all supported share payloads.
sealed class ShareContent {
  const ShareContent();

  const factory ShareContent.image({
    required ShareImageSource image,
    ShareImageSource? thumbnail,
  }) = ShareImageContent;

  const factory ShareContent.webpage({
    required String title,
    required String description,
    required String url,
    ShareImageSource? thumbnail,
  }) = ShareWebPageContent;
}

/// Image share payload.
final class ShareImageContent extends ShareContent {
  const ShareImageContent({
    required this.image,
    this.thumbnail,
  });

  final ShareImageSource image;
  final ShareImageSource? thumbnail;
}

/// Web page share payload.
final class ShareWebPageContent extends ShareContent {
  const ShareWebPageContent({
    required this.title,
    required this.description,
    required this.url,
    this.thumbnail,
  });

  final String title;
  final String description;
  final String url;
  final ShareImageSource? thumbnail;
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

  ShareClient get client;

  Set<ShareChannel> get supportedChannels;

  bool get isInitialized;

  Future<void> initialize();

  Future<bool> isClientInstalled();

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
    for (final channel in provider.supportedChannels) {
      if (channel.client != provider.client) {
        throw ShareBridgeException(
          ShareResultCode.configError,
          'Provider ${provider.providerId} cannot register channel '
          '${channel.id} for client ${channel.client.id}.',
        );
      }
    }
    if (!provider.isInitialized) {
      await provider.initialize();
    }
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

  Future<bool> isInstalled(ShareClient client) async {
    final provider = _findProviderByClient(client);
    if (provider == null) {
      return false;
    }
    if (!provider.isInitialized) {
      try {
        await provider.initialize();
      } catch (_) {
        return false;
      }
    }
    return provider.isClientInstalled();
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

    if (!await provider.isClientInstalled()) {
      return ShareResult(
        code: ShareResultCode.appNotInstalled,
        message: '${channel.client.id} is not installed.',
      );
    }

    return provider.share(channel: channel, content: content);
  }

  ShareProvider? _findProvider(ShareChannel channel) {
    final provider = _findProviderByClient(channel.client);
    if (provider != null && provider.supportedChannels.contains(channel)) {
      return provider;
    }
    return null;
  }

  ShareProvider? _findProviderByClient(ShareClient client) {
    for (final provider in _providers) {
      if (provider.client == client) {
        return provider;
      }
    }
    return null;
  }

  ShareResult? _validate(ShareContent content) {
    return switch (content) {
      ShareImageContent(:final image)
          when _validateImageSource(image) != null =>
        _validateImageSource(image),
      ShareImageContent(:final thumbnail)
          when thumbnail != null && _validateImageSource(thumbnail) != null =>
        _validateImageSource(thumbnail),
      ShareWebPageContent(:final thumbnail)
          when thumbnail != null && _validateImageSource(thumbnail) != null =>
        _validateImageSource(thumbnail),
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
      ShareWebPageContent(
        :final url,
      )
          when Uri.tryParse(url)?.hasScheme != true =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'url must be an absolute URI.',
        ),
      _ => null,
    };
  }

  ShareResult? _validateImageSource(ShareImageSource image) {
    return switch (image) {
      ShareFileImageSource(:final path) when path.trim().isEmpty =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'image file path must not be empty.',
        ),
      ShareMemoryImageSource(:final bytes) when bytes.isEmpty =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'image bytes must not be empty.',
        ),
      ShareMemoryImageSource(:final mimeType)
          when mimeType != null && mimeType.trim().isEmpty =>
        const ShareResult(
          code: ShareResultCode.invalidArgument,
          message: 'image mimeType must not be empty.',
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

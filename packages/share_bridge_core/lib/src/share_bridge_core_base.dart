import 'dart:typed_data';

/// A concrete client app such as WeChat or QQ.
///
/// This is a value object so future packages can add clients without changing
/// `share_bridge_core`.
final class ShareClient {
  /// Creates a client identified by [id].
  const ShareClient(this.id);

  /// WeChat client.
  static const wechat = ShareClient('wechat');

  /// QQ client.
  static const qq = ShareClient('qq');

  /// Stable client identifier used by providers and channels.
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
  /// Creates a share destination for [client].
  const ShareChannel({
    required this.id,
    required this.client,
  });

  /// WeChat session destination.
  static const wechatSession = ShareChannel(
    id: 'wechat.session',
    client: ShareClient.wechat,
  );

  /// WeChat timeline destination.
  static const wechatTimeline = ShareChannel(
    id: 'wechat.timeline',
    client: ShareClient.wechat,
  );

  /// QQ friend destination.
  static const qqFriend = ShareChannel(
    id: 'qq.friend',
    client: ShareClient.qq,
  );

  /// QZone destination.
  static const qzone = ShareChannel(
    id: 'qq.qzone',
    client: ShareClient.qq,
  );

  /// Stable channel identifier.
  final String id;

  /// Client app that owns this destination.
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

  /// Uses an image that is already available as a local file.
  const factory ShareImageSource.file(String path) = ShareFileImageSource;

  /// Uses image bytes that are already loaded in memory.
  const factory ShareImageSource.memory(
    Uint8List bytes, {
    String? mimeType,
  }) = ShareMemoryImageSource;
}

/// Image data already available as a readable local file.
final class ShareFileImageSource extends ShareImageSource {
  /// Creates a local-file image source.
  const ShareFileImageSource(this.path);

  /// Readable local file path.
  final String path;
}

/// Image data already loaded in memory.
final class ShareMemoryImageSource extends ShareImageSource {
  /// Creates an in-memory image source.
  const ShareMemoryImageSource(
    this.bytes, {
    this.mimeType,
  });

  /// Encoded image bytes.
  final Uint8List bytes;

  /// Optional MIME type, such as `image/png`.
  final String? mimeType;
}

/// Base class for all supported share payloads.
sealed class ShareContent {
  const ShareContent();

  /// Creates an image share payload.
  const factory ShareContent.image({
    required ShareImageSource image,
    ShareImageSource? thumbnail,
  }) = ShareImageContent;

  /// Creates a webpage share payload.
  const factory ShareContent.webpage({
    required String title,
    required String description,
    required String url,
    ShareImageSource? thumbnail,
  }) = ShareWebPageContent;
}

/// Image share payload.
final class ShareImageContent extends ShareContent {
  /// Creates an image share payload.
  const ShareImageContent({
    required this.image,
    this.thumbnail,
  });

  /// Main image to share.
  final ShareImageSource image;

  /// Optional thumbnail image.
  final ShareImageSource? thumbnail;
}

/// Web page share payload.
final class ShareWebPageContent extends ShareContent {
  /// Creates a webpage share payload.
  const ShareWebPageContent({
    required this.title,
    required this.description,
    required this.url,
    this.thumbnail,
  });

  /// Webpage title shown by the target app.
  final String title;

  /// Webpage description shown by the target app.
  final String description;

  /// Absolute webpage URL.
  final String url;

  /// Optional thumbnail image.
  final ShareImageSource? thumbnail;
}

/// Normalized result returned by every share provider.
final class ShareResult {
  /// Creates a normalized share result.
  const ShareResult({
    required this.code,
    this.message,
    this.raw,
  });

  /// Result code shared by all providers.
  final ShareResultCode code;

  /// Optional human-readable message.
  final String? message;

  /// Optional native or provider-specific payload.
  final Object? raw;

  /// Whether [code] is [ShareResultCode.success].
  bool get isSuccess => code == ShareResultCode.success;

  /// Whether [code] is [ShareResultCode.cancelled].
  bool get isCancelled => code == ShareResultCode.cancelled;
}

/// Cross-provider result codes.
enum ShareResultCode {
  /// The share request completed successfully.
  success,

  /// The user cancelled the share request.
  cancelled,

  /// The target SDK reported a generic failure.
  failed,

  /// The provider does not support the requested channel.
  unsupportedChannel,

  /// The provider does not support the requested content.
  unsupportedContent,

  /// The target client app is not installed.
  appNotInstalled,

  /// The native SDK has not been initialized.
  sdkNotInitialized,

  /// The share arguments are invalid.
  invalidArgument,

  /// The host app configuration is invalid.
  configError,

  /// A privacy or permission requirement is not satisfied.
  permissionDenied,

  /// The native layer reported an error.
  nativeError,

  /// The share callback timed out.
  timeout,

  /// A previous share request is still pending.
  busy,

  /// Unknown or unmapped result.
  unknown,
}

/// Platform-specific share implementation contract.
abstract interface class ShareProvider {
  /// Stable provider identifier.
  String get providerId;

  /// Client app handled by this provider.
  ShareClient get client;

  /// Channels handled by this provider.
  Set<ShareChannel> get supportedChannels;

  /// Whether the provider has completed SDK initialization.
  bool get isInitialized;

  /// Initializes the provider and native SDK.
  Future<void> initialize();

  /// Returns whether the target client app is installed.
  Future<bool> isClientInstalled();

  /// Returns whether [content] can be shared to [channel].
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  });

  /// Shares [content] to [channel].
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  });
}

/// Registry and dispatcher for share providers.
final class ShareManager {
  final List<ShareProvider> _providers = <ShareProvider>[];

  /// Registers and initializes [provider].
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
    _providers.removeWhere((item) => item.providerId == provider.providerId);
    _providers.add(provider);
    if (!provider.isInitialized) {
      await provider.initialize();
    }
  }

  /// Channels currently available from registered providers.
  Set<ShareChannel> get registeredChannels {
    return {
      for (final provider in _providers) ...provider.supportedChannels,
    };
  }

  /// Initializes every registered provider that is not initialized yet.
  Future<void> initializeAll() async {
    for (final provider in _providers) {
      if (!provider.isInitialized) {
        await provider.initialize();
      }
    }
  }

  /// Returns whether [client] is installed.
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

  /// Shares [content] to [channel] through the matching provider.
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
  /// Creates a Share Bridge exception.
  const ShareBridgeException(
    this.code,
    this.message, {
    this.cause,
  });

  /// Result code represented by this exception.
  final ShareResultCode code;

  /// Human-readable exception message.
  final String message;

  /// Optional original exception or platform payload.
  final Object? cause;

  @override
  String toString() {
    return 'ShareBridgeException($code, $message)';
  }
}

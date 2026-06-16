import 'dart:typed_data';

import 'package:share_bridge_core/share_bridge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShareChannel', () {
    test('compares by id', () {
      expect(
        const ShareChannel(
          id: 'wechat.session',
          client: ShareClient.wechat,
        ),
        ShareChannel.wechatSession,
      );
      expect(
        {ShareChannel.wechatSession}.contains(
          const ShareChannel(
            id: 'wechat.session',
            client: ShareClient.wechat,
          ),
        ),
        isTrue,
      );
    });

    test('built-in channels are linked to clients', () {
      expect(ShareChannel.wechatSession.client, ShareClient.wechat);
      expect(ShareChannel.wechatTimeline.client, ShareClient.wechat);
      expect(ShareChannel.qqFriend.client, ShareClient.qq);
      expect(ShareChannel.qzone.client, ShareClient.qq);
    });
  });

  group('ShareManager', () {
    test('returns unsupportedChannel when no provider is registered', () async {
      final manager = ShareManager();

      final result = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.webpage(
          title: 'Title',
          description: 'Description',
          url: 'https://example.com',
        ),
      );

      expect(result.code, ShareResultCode.unsupportedChannel);
    });

    test('initializes provider when registering', () async {
      final provider = _FakeProvider(
        supportedChannels: {ShareChannel.wechatSession},
      );
      final manager = ShareManager();
      await manager.register(provider);

      expect(provider.initializeCount, 1);

      final result = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.webpage(
          title: 'Title',
          description: 'Description',
          url: 'https://example.com',
        ),
      );

      expect(result.code, ShareResultCode.success);
      expect(provider.initializeCount, 1);
    });

    test('returns unsupportedContent when provider rejects content', () async {
      final provider = _FakeProvider(
        supportedChannels: {ShareChannel.wechatSession},
        supportsContent: false,
      );
      final manager = ShareManager();
      await manager.register(provider);

      final result = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.image(
          image: ShareImageSource.file('/tmp/a.png'),
        ),
      );

      expect(result.code, ShareResultCode.unsupportedContent);
    });

    test('checks installation by client', () async {
      final provider = _FakeProvider(
        supportedChannels: {ShareChannel.wechatSession},
      );
      final manager = ShareManager();
      await manager.register(provider);

      final installed = await manager.isInstalled(ShareClient.wechat);

      expect(installed, isTrue);
      expect(provider.initializeCount, 1);
    });

    test('returns appNotInstalled before sharing', () async {
      final provider = _FakeProvider(
        supportedChannels: {ShareChannel.wechatSession},
        installed: false,
      );
      final manager = ShareManager();
      await manager.register(provider);

      final result = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.webpage(
          title: 'Title',
          description: 'Description',
          url: 'https://example.com',
        ),
      );

      expect(result.code, ShareResultCode.appNotInstalled);
    });

    test('rejects provider channels from another client', () async {
      final manager = ShareManager();

      expect(
        manager.register(
          _FakeProvider(
            client: ShareClient.wechat,
            supportedChannels: {ShareChannel.qqFriend},
          ),
        ),
        throwsA(isA<ShareBridgeException>()),
      );
    });

    test('validates empty webpage fields', () async {
      final manager = ShareManager();

      final result = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.webpage(
          title: '',
          description: 'Description',
          url: 'https://example.com',
        ),
      );

      expect(result.code, ShareResultCode.invalidArgument);
    });

    test('validates image source', () async {
      final manager = ShareManager();

      final emptyFile = await manager.share(
        channel: ShareChannel.wechatSession,
        content: const ShareContent.image(
          image: ShareImageSource.file(''),
        ),
      );
      final emptyBytes = await manager.share(
        channel: ShareChannel.wechatSession,
        content: ShareContent.image(
          image: ShareImageSource.memory(Uint8List(0)),
        ),
      );

      expect(emptyFile.code, ShareResultCode.invalidArgument);
      expect(emptyBytes.code, ShareResultCode.invalidArgument);
    });

    test('exposes registered channels', () async {
      final manager = ShareManager();
      await manager.register(
        _FakeProvider(
          supportedChannels: {
            ShareChannel.wechatSession,
            ShareChannel.wechatTimeline,
          },
        ),
      );

      expect(
        manager.registeredChannels,
        containsAll({
          ShareChannel.wechatSession,
          ShareChannel.wechatTimeline,
        }),
      );
    });
  });
}

final class _FakeProvider implements ShareProvider {
  _FakeProvider({
    required this.supportedChannels,
    this.client = ShareClient.wechat,
    this.supportsContent = true,
    this.installed = true,
  });

  @override
  final ShareClient client;

  @override
  final Set<ShareChannel> supportedChannels;

  final bool supportsContent;
  final bool installed;

  int initializeCount = 0;

  @override
  String get providerId => 'fake';

  @override
  bool get isInitialized => initializeCount > 0;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<bool> isClientInstalled() async => installed;

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    return supportsContent;
  }

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    return const ShareResult(code: ShareResultCode.success);
  }
}

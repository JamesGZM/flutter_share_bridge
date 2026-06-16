import 'package:share_bridge_core/share_bridge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShareChannel', () {
    test('compares by id', () {
      expect(
        const ShareChannel('wechat.session'),
        ShareChannel.wechatSession,
      );
      expect(
        {ShareChannel.wechatSession}.contains(
          const ShareChannel('wechat.session'),
        ),
        isTrue,
      );
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

    test('lazy initializes provider before sharing', () async {
      final provider = _FakeProvider(
        supportedChannels: {ShareChannel.wechatSession},
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
        content: const ShareContent.image(imagePath: '/tmp/a.png'),
      );

      expect(result.code, ShareResultCode.unsupportedContent);
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
    this.supportsContent = true,
  });

  @override
  final Set<ShareChannel> supportedChannels;

  final bool supportsContent;

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
  Future<bool> isInstalled({ShareChannel? channel}) async => true;

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

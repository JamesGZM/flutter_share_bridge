import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_widgets/share_bridge_widgets.dart';

void main() {
  testWidgets('ShareBridgeGrid renders channels and shares on tap', (
    tester,
  ) async {
    final provider = _FakeProvider();
    final manager = ShareManager();
    await manager.register(provider);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareBridgeGrid(
            manager: manager,
            content: const ShareContent.webpage(
              title: 'Title',
              description: 'Description',
              url: 'https://example.com',
            ),
            channels: const [ShareChannel.wechatSession],
          ),
        ),
      ),
    );

    expect(find.text('微信'), findsOneWidget);

    await tester.tap(find.text('微信'));
    await tester.pump();

    expect(provider.shareCount, 1);
  });
}

final class _FakeProvider implements ShareProvider {
  int shareCount = 0;
  bool _initialized = false;

  @override
  String get providerId => 'fake';

  @override
  ShareClient get client => ShareClient.wechat;

  @override
  Set<ShareChannel> get supportedChannels => {
        ShareChannel.wechatSession,
      };

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> isClientInstalled() async => true;

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    return true;
  }

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    shareCount += 1;
    return const ShareResult(code: ShareResultCode.success);
  }
}

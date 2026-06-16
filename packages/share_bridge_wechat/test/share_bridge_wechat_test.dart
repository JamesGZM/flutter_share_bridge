import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_wechat/share_bridge_wechat.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

class MockShareBridgeWechatPlatform
    with MockPlatformInterfaceMixin
    implements ShareBridgeWechatPlatform {
  bool initialized = false;

  @override
  Future<void> initialize({
    required String appId,
    String? universalLink,
  }) async {
    initialized = true;
  }

  @override
  Future<bool> isInstalled() async => true;

  @override
  Future<ShareResult> shareImage({
    required String requestId,
    required ShareChannel channel,
    required ShareImageContent content,
  }) async {
    return const ShareResult(code: ShareResultCode.success);
  }

  @override
  Future<ShareResult> shareWebPage({
    required String requestId,
    required ShareChannel channel,
    required ShareWebPageContent content,
  }) async {
    return const ShareResult(code: ShareResultCode.success);
  }
}

void main() {
  final initialPlatform = ShareBridgeWechatPlatform.instance;

  tearDown(() {
    ShareBridgeWechatPlatform.instance = initialPlatform;
  });

  test('$MethodChannelShareBridgeWechat is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelShareBridgeWechat>());
  });

  test('initialize does not require plugin privacy flag', () async {
    final fakePlatform = MockShareBridgeWechatPlatform();
    ShareBridgeWechatPlatform.instance = fakePlatform;
    final provider = WechatShareProvider(appId: 'wx123');

    await provider.initialize();

    expect(fakePlatform.initialized, isTrue);
  });

  test('shares webpage through platform', () async {
    final fakePlatform = MockShareBridgeWechatPlatform();
    ShareBridgeWechatPlatform.instance = fakePlatform;
    final provider = WechatShareProvider(appId: 'wx123');

    await provider.initialize();
    final result = await provider.share(
      channel: ShareChannel.wechatSession,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(fakePlatform.initialized, isTrue);
    expect(result.code, ShareResultCode.success);
  });
}

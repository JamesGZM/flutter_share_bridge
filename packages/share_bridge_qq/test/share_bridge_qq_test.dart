import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_qq/share_bridge_qq.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

class MockShareBridgeQqPlatform
    with MockPlatformInterfaceMixin
    implements ShareBridgeQqPlatform {
  bool initialized = false;
  bool? receivedPrivacyGranted;

  @override
  Future<void> initialize({
    required String appId,
    String? universalLink,
  }) async {
    initialized = true;
  }

  @override
  Future<void> setPrivacyGranted(bool granted) async {
    receivedPrivacyGranted = granted;
  }

  @override
  Future<bool> isInstalled() async => true;

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    return true;
  }

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
  final initialPlatform = ShareBridgeQqPlatform.instance;

  tearDown(() {
    ShareBridgeQqPlatform.instance = initialPlatform;
  });

  test('$MethodChannelShareBridgeQq is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelShareBridgeQq>());
  });

  test('setPrivacyGranted delegates to platform', () async {
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgeQqPlatform.instance = fakePlatform;

    await QqShareProvider.setPrivacyGranted(true);

    expect(fakePlatform.receivedPrivacyGranted, isTrue);
  });

  test('shares webpage through platform', () async {
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgeQqPlatform.instance = fakePlatform;
    final provider = QqShareProvider(appId: '101');

    await provider.initialize();
    final result = await provider.share(
      channel: ShareChannel.qqFriend,
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

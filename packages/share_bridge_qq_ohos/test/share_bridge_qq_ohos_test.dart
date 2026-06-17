import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_qq_ohos/share_bridge_qq_ohos.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.qq);
  final platform = ShareBridgeQqOhos();
  const channel = MethodChannel('share_bridge_qq');

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: initialPlatform,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('registerWith installs HarmonyOS implementation', () {
    ShareBridgeQqOhos.registerWith();

    expect(
      ShareBridgePlatform.instanceFor(ShareClient.qq),
      isA<ShareBridgeQqOhos>(),
    );
  });

  test('supports delegates supported content to method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      expect(methodCall.method, 'supports');
      expect(methodCall.arguments, containsPair('channel', 'qq.friend'));
      expect(methodCall.arguments, containsPair('contentType', 'webpage'));
      return true;
    });

    final supported = await platform.supports(
      channel: ShareChannel.qqFriend,
      content: const ShareWebPageContent(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(supported, isTrue);
  });

  test('does not support qzone image', () async {
    final supported = await platform.supports(
      channel: ShareChannel.qzone,
      content: const ShareImageContent(
        image: ShareImageSource.file('/tmp/a.png'),
      ),
    );

    expect(supported, isFalse);
  });

  test('shareWebPage returns signer requirement', () async {
    final result = await platform.shareWebPage(
      requestId: '1',
      channel: ShareChannel.qqFriend,
      content: const ShareWebPageContent(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.unsupportedContent);
    expect(result.message, contains('qqHarmonySigner'));
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_qq_android/share_bridge_qq_android.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.qq);
  final platform = ShareBridgeQqAndroid();
  const channel = MethodChannel('share_bridge_qq');

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: initialPlatform,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('registerWith installs Android implementation', () {
    ShareBridgeQqAndroid.registerWith();

    expect(
      ShareBridgePlatform.instanceFor(ShareClient.qq),
      isA<ShareBridgeQqAndroid>(),
    );
  });

  test('supports delegates to method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return true;
    });

    final supported = await platform.supports(
      channel: ShareChannel.qzone,
      content: const ShareImageContent(
        image: ShareImageSource.file('/tmp/a.png'),
      ),
    );

    expect(supported, isTrue);
  });

  test('shareWebPage maps native result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return {'code': 'success', 'message': null};
    });

    final result = await platform.shareWebPage(
      requestId: '1',
      channel: ShareChannel.qqFriend,
      content: const ShareWebPageContent(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.success);
  });

  test('shareImage encodes image source', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      receivedCall = methodCall;
      return {'code': 'success', 'message': null};
    });

    await platform.shareImage(
      requestId: '1',
      channel: ShareChannel.qqFriend,
      content: const ShareImageContent(
        image: ShareImageSource.file('/tmp/a.png'),
      ),
    );

    expect(receivedCall?.method, 'shareImage');
    final arguments = receivedCall?.arguments as Map<Object?, Object?>;
    expect(arguments['image'], containsPair('type', 'file'));
    expect(arguments['image'], containsPair('path', '/tmp/a.png'));
  });
}

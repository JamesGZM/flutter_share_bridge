import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';
import 'package:share_bridge_wechat_ohos/share_bridge_wechat_ohos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.wechat);
  final platform = ShareBridgeWechatOhos();
  const channel = MethodChannel('share_bridge_wechat');

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.wechat,
      instance: initialPlatform,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('registerWith installs HarmonyOS implementation', () {
    ShareBridgeWechatOhos.registerWith();

    expect(
      ShareBridgePlatform.instanceFor(ShareClient.wechat),
      isA<ShareBridgeWechatOhos>(),
    );
  });

  test('supports delegates to method channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          expect(methodCall.method, 'supports');
          expect(
            methodCall.arguments,
            containsPair('channel', 'wechat.session'),
          );
          expect(methodCall.arguments, containsPair('contentType', 'webpage'));
          return true;
        });

    final supported = await platform.supports(
      channel: ShareChannel.wechatSession,
      content: const ShareWebPageContent(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(supported, isTrue);
  });

  test('shareWebPage encodes webpage arguments', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          receivedCall = methodCall;
          return {'code': 'success', 'message': null};
        });

    final result = await platform.shareWebPage(
      requestId: '1',
      channel: ShareChannel.wechatSession,
      content: const ShareWebPageContent(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
        thumbnail: ShareImageSource.file('/tmp/thumb.png'),
      ),
    );

    expect(result.code, ShareResultCode.success);
    expect(receivedCall?.method, 'shareWebPage');
    final arguments = receivedCall?.arguments as Map<Object?, Object?>;
    expect(arguments['requestId'], '1');
    expect(arguments['channel'], 'wechat.session');
    expect(arguments['title'], 'Title');
    expect(arguments['thumbnail'], containsPair('path', '/tmp/thumb.png'));
  });

  test('shareImage encodes image source', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          receivedCall = methodCall;
          return {'code': 'success', 'message': null};
        });

    final result = await platform.shareImage(
      requestId: '1',
      channel: ShareChannel.wechatTimeline,
      content: const ShareImageContent(
        image: ShareImageSource.file('/tmp/image.png'),
      ),
    );

    expect(result.code, ShareResultCode.success);
    expect(receivedCall?.method, 'shareImage');
    final arguments = receivedCall?.arguments as Map<Object?, Object?>;
    expect(arguments['channel'], 'wechat.timeline');
    expect(arguments['image'], containsPair('type', 'file'));
    expect(arguments['image'], containsPair('path', '/tmp/image.png'));
  });
}

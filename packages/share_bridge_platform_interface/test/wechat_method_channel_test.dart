import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_core/share_bridge_core.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelShareBridgeWechat();
  const channel = MethodChannel('share_bridge_wechat');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return switch (methodCall.method) {
        'initialize' => null,
        'isInstalled' => true,
        'shareWebPage' => {
            'code': 'success',
            'message': null,
          },
        'shareImage' => {
            'code': 'cancelled',
            'message': 'cancelled',
          },
        _ => throw PlatformException(code: 'unimplemented'),
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isInstalled delegates to method channel', () async {
    expect(await platform.isInstalled(), isTrue);
  });

  test('shareWebPage maps native result', () async {
    final result = await platform.shareWebPage(
      requestId: '1',
      channel: ShareChannel.wechatSession,
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
      return {
        'code': 'success',
        'message': null,
      };
    });

    await platform.shareImage(
      requestId: '1',
      channel: ShareChannel.wechatSession,
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

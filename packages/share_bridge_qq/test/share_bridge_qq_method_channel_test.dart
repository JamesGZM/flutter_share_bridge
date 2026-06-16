import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_core/share_bridge_core.dart';
import 'package:share_bridge_qq/share_bridge_qq_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelShareBridgeQq();
  const channel = MethodChannel('share_bridge_qq');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return switch (methodCall.method) {
        'initialize' => null,
        'isInstalled' => true,
        'supports' => true,
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

  test('supports delegates to method channel', () async {
    final supported = await platform.supports(
      channel: ShareChannel.qzone,
      content: const ShareImageContent(imagePath: '/tmp/a.png'),
    );

    expect(supported, isTrue);
  });

  test('shareWebPage maps native result', () async {
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
}

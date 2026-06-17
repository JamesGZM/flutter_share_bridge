import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_bridge_qq/share_bridge_qq.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

class MockShareBridgeQqPlatform
    with MockPlatformInterfaceMixin
    implements ShareBridgePlatform {
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
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.qq);
  const methodChannel = MethodChannel('share_bridge_qq');

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: initialPlatform,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('setPrivacyGranted delegates to QQ method channel', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      receivedCall = methodCall;
      return null;
    });

    await QqShareProvider.setPrivacyGranted(true);

    expect(receivedCall?.method, 'setPrivacyGranted');
    expect(receivedCall?.arguments, containsPair('granted', true));
  });

  test('shares webpage through platform', () async {
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
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

  test('qqHarmonySigner is not called for non-Harmony platform', () async {
    var signerCalled = false;
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
    final provider = QqShareProvider(
      appId: '101',
      qqHarmonySigner: (_) async {
        signerCalled = true;
        return const QqHarmonyShareSignature(
          type: 2,
          shareJson: {},
          timestamp: '1',
          nonce: '2',
          shareJsonSign: 'sign',
        );
      },
    );

    final result = await provider.share(
      channel: ShareChannel.qqFriend,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.success);
    expect(signerCalled, isFalse);
  });

  test('returns unsupportedContent when Harmony signer is missing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'supportsHarmonySignedShare') {
        return true;
      }
      return null;
    });
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
    final provider = QqShareProvider(appId: '101');

    final result = await provider.share(
      channel: ShareChannel.qqFriend,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.unsupportedContent);
    expect(result.message, contains('qqHarmonySigner'));
  });

  test('qqHarmonySigner receives request and delegates signed data', () async {
    late QqHarmonyShareSignatureRequest receivedRequest;
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'supportsHarmonySignedShare') {
        return true;
      }
      receivedCall = methodCall;
      return {'code': 'success', 'message': null};
    });
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
    final provider = QqShareProvider(
      appId: '101',
      qqHarmonySigner: (request) async {
        receivedRequest = request;
        return QqHarmonyShareSignature(
          type: request.type,
          shareJson: request.shareJson,
          timestamp: '123',
          nonce: '456',
          shareJsonSign: 'sign',
          openId: 'openid',
        );
      },
    );

    final result = await provider.share(
      channel: ShareChannel.qqFriend,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.success);
    expect(receivedRequest.channel, ShareChannel.qqFriend);
    expect(receivedRequest.type, 2);
    expect(receivedRequest.shareJson, containsPair('title', 'Title'));
    expect(receivedCall?.method, 'shareHarmonySigned');
    final arguments = receivedCall?.arguments as Map<Object?, Object?>;
    expect(arguments['channel'], 'qq.friend');
    expect(arguments['timestamp'], '123');
    expect(arguments['nonce'], '456');
    expect(arguments['shareJsonSign'], 'sign');
    expect(arguments['openId'], 'openid');
  });

  test('maps ShareBridgeException from qqHarmonySigner', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'supportsHarmonySignedShare') {
        return true;
      }
      return null;
    });
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
    final provider = QqShareProvider(
      appId: '101',
      qqHarmonySigner: (_) async {
        throw const ShareBridgeException(
          ShareResultCode.permissionDenied,
          'not allowed',
        );
      },
    );

    final result = await provider.share(
      channel: ShareChannel.qqFriend,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.permissionDenied);
    expect(result.message, 'not allowed');
  });

  test('maps ordinary error from qqHarmonySigner', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method == 'supportsHarmonySignedShare') {
        return true;
      }
      return null;
    });
    final fakePlatform = MockShareBridgeQqPlatform();
    ShareBridgePlatform.register(
        client: ShareClient.qq, instance: fakePlatform);
    final provider = QqShareProvider(
      appId: '101',
      qqHarmonySigner: (_) async => throw StateError('server failed'),
    );

    final result = await provider.share(
      channel: ShareChannel.qqFriend,
      content: const ShareContent.webpage(
        title: 'Title',
        description: 'Description',
        url: 'https://example.com',
      ),
    );

    expect(result.code, ShareResultCode.nativeError);
    expect(result.message, 'QQ HarmonyOS share signing failed.');
  });
}

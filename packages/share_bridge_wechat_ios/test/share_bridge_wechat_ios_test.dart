import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';
import 'package:share_bridge_wechat_ios/share_bridge_wechat_ios.dart';

void main() {
  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.wechat);

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.wechat,
      instance: initialPlatform,
    );
  });

  test('registerWith installs iOS implementation', () {
    ShareBridgeWechatIOS.registerWith();

    expect(
      ShareBridgePlatform.instanceFor(ShareClient.wechat),
      isA<ShareBridgeWechatIOS>(),
    );
  });
}

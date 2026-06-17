import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_qq_ios/share_bridge_qq_ios.dart';
import 'package:share_bridge_platform_interface/share_bridge_platform_interface.dart';

void main() {
  final initialPlatform = ShareBridgePlatform.instanceFor(ShareClient.qq);

  tearDown(() {
    ShareBridgePlatform.register(
      client: ShareClient.qq,
      instance: initialPlatform,
    );
  });

  test('registerWith installs iOS implementation', () {
    ShareBridgeQqIOS.registerWith();

    expect(
      ShareBridgePlatform.instanceFor(ShareClient.qq),
      isA<ShareBridgeQqIOS>(),
    );
  });
}

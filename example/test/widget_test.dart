import 'package:flutter_test/flutter_test.dart';
import 'package:share_bridge_example/main.dart';

void main() {
  testWidgets('renders aggregate share example', (tester) async {
    await tester.pumpWidget(const ShareBridgeExampleApp());

    expect(find.text('Share Bridge Example'), findsOneWidget);
    expect(find.text('初始化并检查安装'), findsOneWidget);
    expect(find.text('打开聚合分享面板'), findsOneWidget);
    expect(find.text('分享到微信好友'), findsOneWidget);
    expect(find.text('分享到 QQ 好友'), findsOneWidget);
  });
}

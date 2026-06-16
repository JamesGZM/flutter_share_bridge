import 'package:flutter/material.dart';
import 'package:share_bridge_qq/share_bridge_qq.dart';
import 'package:share_bridge_wechat/share_bridge_wechat.dart';
import 'package:share_bridge_widgets/share_bridge_widgets.dart';

const _wechatAppId = String.fromEnvironment(
  'WECHAT_APP_ID',
  defaultValue: 'your_wechat_app_id',
);
const _wechatUniversalLink = String.fromEnvironment('WECHAT_UNIVERSAL_LINK');
const _qqAppId = String.fromEnvironment(
  'QQ_APP_ID',
  defaultValue: 'your_qq_app_id',
);
const _qqUniversalLink = String.fromEnvironment('QQ_UNIVERSAL_LINK');

void main() {
  runApp(const ShareBridgeExampleApp());
}

class ShareBridgeExampleApp extends StatelessWidget {
  const ShareBridgeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Bridge Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ShareBridgeExampleHome(),
    );
  }
}

class ShareBridgeExampleHome extends StatefulWidget {
  const ShareBridgeExampleHome({super.key});

  @override
  State<ShareBridgeExampleHome> createState() => _ShareBridgeExampleHomeState();
}

class _ShareBridgeExampleHomeState extends State<ShareBridgeExampleHome> {
  final ShareManager _manager = ShareManager();
  late final WechatShareProvider _wechat = WechatShareProvider(
    appId: _wechatAppId,
    universalLink: _emptyToNull(_wechatUniversalLink),
  );
  late final QqShareProvider _qq = QqShareProvider(
    appId: _qqAppId,
    universalLink: _emptyToNull(_qqUniversalLink),
  );

  String _status = '未初始化';

  static String? _emptyToNull(String value) {
    return value.isEmpty ? null : value;
  }

  Future<void> _initialize() async {
    try {
      await QqShareProvider.setPrivacyGranted(true);
      await _manager.register(_wechat);
      await _manager.register(_qq);
      final wechatInstalled = await _manager.isInstalled(ShareClient.wechat);
      final qqInstalled = await _manager.isInstalled(ShareClient.qq);
      setState(() {
        _status =
            '初始化完成。微信：${_yesNo(wechatInstalled)}，QQ/TIM：${_yesNo(qqInstalled)}';
      });
    } catch (error) {
      setState(() {
        _status = '初始化失败：$error';
      });
    }
  }

  Future<void> _shareSheet() async {
    await _ensureInitialized();
    if (!mounted) {
      return;
    }
    final result = await ShareBridgeSheet.show(
      context: context,
      manager: _manager,
      content: _demoContent,
    );
    if (result != null) {
      setState(() {
        _status =
            '分享结果：${result.code.name}${result.message == null ? '' : '，${result.message}'}';
      });
    }
  }

  Future<void> _shareTo(ShareChannel channel) async {
    await _ensureInitialized();
    final result = await _manager.share(
      channel: channel,
      content: _demoContent,
    );
    setState(() {
      _status =
          '分享结果：${result.code.name}${result.message == null ? '' : '，${result.message}'}';
    });
  }

  Future<void> _ensureInitialized() async {
    if (!_wechat.isInitialized || !_qq.isInitialized) {
      await _initialize();
    }
  }

  String _yesNo(bool value) => value ? '已安装' : '未安装';

  ShareContent get _demoContent {
    return const ShareContent.webpage(
      title: 'Share Bridge 示例',
      description: '同时接入微信、QQ 和可选分享 UI 的聚合示例。',
      url: 'https://example.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Bridge Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Dart 配置'),
          const SizedBox(height: 8),
          const Text('WECHAT_APP_ID: $_wechatAppId'),
          const Text('QQ_APP_ID: $_qqAppId'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _initialize, child: const Text('初始化并检查安装')),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _shareSheet,
            child: const Text('打开聚合分享面板'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _shareTo(ShareChannel.wechatSession),
            child: const Text('分享到微信好友'),
          ),
          OutlinedButton(
            onPressed: () => _shareTo(ShareChannel.wechatTimeline),
            child: const Text('分享到微信朋友圈'),
          ),
          OutlinedButton(
            onPressed: () => _shareTo(ShareChannel.qqFriend),
            child: const Text('分享到 QQ 好友'),
          ),
          OutlinedButton(
            onPressed: () => _shareTo(ShareChannel.qzone),
            child: const Text('分享到 QQ 空间'),
          ),
          const SizedBox(height: 16),
          Text(_status),
          const SizedBox(height: 24),
          const Text(
            '真机调试前还要修改 AndroidManifest.xml、Info.plist、开放平台包名/签名/Bundle ID、URL Scheme 和 Universal Link。dart-define 不会自动修改宿主配置。',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:share_bridge_qq/share_bridge_qq.dart';

const _appId = String.fromEnvironment(
  'QQ_APP_ID',
  defaultValue: 'your_qq_app_id',
);

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  late final QqShareProvider _provider = QqShareProvider(appId: _appId);
  String _status = '未初始化';

  Future<void> _initialize() async {
    try {
      QqShareProvider.setPrivacyGranted(true);
      await _provider.initialize();
      final installed = await _provider.isInstalled();
      setState(() {
        _status = installed ? '已初始化，QQ 已安装' : '已初始化，QQ 未安装';
      });
    } catch (error) {
      setState(() {
        _status = '初始化失败：$error';
      });
    }
  }

  Future<void> _share(ShareChannel channel) async {
    if (!_provider.isInitialized) {
      await _initialize();
    }
    final result = await _provider.share(
      channel: channel,
      content: const ShareContent.webpage(
        title: 'Share Bridge QQ 示例',
        description: '本地调试 QQ / QQ 空间网页分享。',
        url: 'https://example.com',
      ),
    );
    setState(() {
      _status =
          '分享结果：${result.code.name}${result.message == null ? '' : '，${result.message}'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Bridge QQ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AppID: $_appId'),
            const SizedBox(height: 8),
            Text('Provider: ${_provider.providerId}'),
            const SizedBox(height: 8),
            Text('Channels: ${_provider.supportedChannels.join(', ')}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _initialize,
              child: const Text('初始化并检查安装'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _share(ShareChannel.qqFriend),
              child: const Text('分享网页到 QQ 好友'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _share(ShareChannel.qzone),
              child: const Text('分享网页到 QQ 空间'),
            ),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}

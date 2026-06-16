import 'package:flutter/material.dart';
import 'package:share_bridge_wechat/share_bridge_wechat.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  static const _appId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: 'your_wechat_app_id',
  );

  final _manager = ShareManager();
  late final WechatShareProvider _provider;
  ShareResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _provider = WechatShareProvider(appId: _appId);
    _setup();
  }

  Future<void> _setup() async {
    await WechatShareProvider.setPrivacyGranted(true);
    await _manager.register(_provider);
  }

  Future<void> _share(ShareChannel channel) async {
    final result = await _manager.share(
      channel: channel,
      content: const ShareContent.webpage(
        title: 'Share Bridge',
        description: '微信 Android 分享调试',
        url: 'https://example.com',
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Share Bridge WeChat')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AppID: $_appId'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _share(ShareChannel.wechatSession),
                child: const Text('分享到微信好友'),
              ),
              FilledButton(
                onPressed: () => _share(ShareChannel.wechatTimeline),
                child: const Text('分享到朋友圈'),
              ),
              const SizedBox(height: 12),
              Text('结果: ${_lastResult?.code.name ?? '-'}'),
              if (_lastResult?.message case final message?)
                Text('消息: $message'),
            ],
          ),
        ),
      ),
    );
  }
}

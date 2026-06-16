import 'package:flutter/material.dart';
import 'package:share_bridge_qq/share_bridge_qq.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = QqShareProvider(appId: 'your_qq_app_id');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Share Bridge QQ')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Provider: ${provider.providerId}\n'
            'Channels: ${provider.supportedChannels.join(', ')}',
          ),
        ),
      ),
    );
  }
}

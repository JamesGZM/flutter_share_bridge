# share_bridge_core

Share Bridge 的纯 Dart 核心库。

这个包定义分享渠道、分享内容、统一结果码、Provider 协议和 `ShareManager`。它不依赖 Flutter、不依赖原生平台 SDK，也不包含任何 UI。

## 使用示例

```dart
final manager = ShareManager();

await manager.register(myProvider);

final result = await manager.share(
  channel: ShareChannel.wechatSession,
  content: const ShareContent.webpage(
    title: '标题',
    description: '描述',
    url: 'https://example.com',
  ),
);
```

## 范围

- 不包含微信或 QQ SDK。
- 不包含 MethodChannel 实现。
- 不包含 UI 组件或品牌图标资源。

# share_bridge_widgets

[English](README.md) | 中文

Share Bridge 的可选 Flutter UI 组件库。

这个包只依赖 `share_bridge_core`，不依赖微信、QQ 或任何原生 SDK。

## 使用示例

```dart
await ShareBridgeSheet.show(
  context: context,
  manager: manager,
  content: const ShareContent.webpage(
    title: '标题',
    description: '描述',
    url: 'https://example.com',
  ),
);
```

如果业务有自己的弹窗，也可以直接嵌入 `ShareBridgeGrid`。

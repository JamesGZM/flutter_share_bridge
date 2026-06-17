# share_bridge_widgets

English | [中文](README.md)

Optional Flutter UI components for Share Bridge.

This package depends only on `share_bridge_core`. It does not depend on WeChat, QQ, or any native SDK.

## Example

```dart
await ShareBridgeSheet.show(
  context: context,
  manager: manager,
  content: const ShareContent.webpage(
    title: 'Title',
    description: 'Description',
    url: 'https://example.com',
  ),
);
```

If your app already has its own dialog, you can embed `ShareBridgeGrid` directly.

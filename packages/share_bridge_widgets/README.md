# share_bridge_widgets

Optional Flutter widgets for Share Bridge.

This package depends only on `share_bridge_core`. It does not depend on WeChat,
QQ, or any native SDK.

## Usage

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

You can also embed `ShareBridgeGrid` in a custom UI.

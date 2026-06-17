# share_bridge_widgets

[![Pub Package](https://img.shields.io/pub/v/share_bridge_widgets.svg)](https://pub.dev/packages/share_bridge_widgets)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

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

If your app already has its own dialog, embed `ShareBridgeGrid` directly.

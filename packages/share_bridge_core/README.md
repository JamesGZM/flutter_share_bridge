# share_bridge_core

Pure Dart core abstractions for Share Bridge.

This package defines channels, share content models, result codes, provider
contracts, and `ShareManager`. It does not depend on Flutter, platform SDKs, or
UI packages.

## Usage

```dart
final manager = ShareManager();

await manager.register(myProvider);

final result = await manager.share(
  channel: ShareChannel.wechatSession,
  content: const ShareContent.webpage(
    title: 'Title',
    description: 'Description',
    url: 'https://example.com',
  ),
);
```

## Scope

- Does not include WeChat or QQ SDKs.
- Does not include MethodChannel code.
- Does not include widgets or brand assets.

# share_bridge_core

English | [中文](README.md)

The pure Dart core library for Share Bridge.

This package defines share clients, share channels, share content models, unified result codes, the Provider contract, and `ShareManager`. It does not depend on Flutter, native platform SDKs, or UI.

## Example

```dart
final manager = ShareManager();

await manager.register(myProvider);

final installed = await manager.isInstalled(ShareClient.wechat);

final result = await manager.share(
  channel: ShareChannel.wechatSession,
  content: const ShareContent.webpage(
    title: 'Title',
    description: 'Description',
    url: 'https://example.com',
  ),
);
```

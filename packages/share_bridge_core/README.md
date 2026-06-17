# share_bridge_core

[![Pub Package](https://img.shields.io/pub/v/share_bridge_core.svg)](https://pub.dev/packages/share_bridge_core)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

The pure Dart core library for Share Bridge.

This package defines share clients, share channels, share content models, unified result codes, the provider contract, and `ShareManager`. It does not depend on Flutter, native platform SDKs, or UI.

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

`ShareClient` represents a real client app, such as WeChat or QQ. `ShareChannel` represents a share destination inside that client, such as WeChat session, WeChat timeline, QQ friend, or QZone.

`ShareManager.register(provider)` initializes the provider immediately. Host apps should register providers only after the user has accepted the app privacy policy and the required platform configuration is ready.

Image sharing supports local files and in-memory bytes only. Network images and Flutter assets should be resolved by the host app before creating `ShareContent.image`.

## Scope

- No WeChat or QQ SDK dependency.
- No MethodChannel implementation.
- No UI components or brand icon assets.

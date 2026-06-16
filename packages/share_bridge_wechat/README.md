# share_bridge_wechat

WeChat share-only provider for Share Bridge.

Current status: Dart API and MethodChannel skeleton are available. Native
Android/iOS WeChat SDK integration is not complete yet.

## Usage Shape

```dart
await WechatShareProvider.setPrivacyGranted(true);

final manager = ShareManager();
await manager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/wechat/',
  ),
);
```

## Scope

- WeChat sharing only.
- No login, payment, OAuth, or user profile APIs.
- Android/iOS native SDK integration will be implemented in a later milestone.

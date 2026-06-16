# share_bridge_qq

Share Bridge 的 QQ 与 QQ 空间分享能力包。

当前状态：Dart API 和 MethodChannel 骨架已完成；Android / iOS QQ 原生 SDK 接入还未完成。

## 使用形态

```dart
await QqShareProvider.setPrivacyGranted(true);

final manager = ShareManager();
await manager.register(
  QqShareProvider(
    appId: 'your_qq_app_id',
    universalLink: 'https://example.com/qq/',
  ),
);
```

## 范围

- 只做 QQ / QQ 空间分享。
- 不做登录、OAuth、用户资料。
- 原生 SDK 接入会在后续里程碑实现。

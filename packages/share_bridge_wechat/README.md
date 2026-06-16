# share_bridge_wechat

Share Bridge 的微信分享能力包。

当前状态：Dart API 和 MethodChannel 骨架已完成；Android / iOS 微信原生 SDK 接入还未完成。

## 使用形态

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

## 范围

- 只做微信分享。
- 不做登录、支付、OAuth、用户资料。
- 原生 SDK 接入会在后续里程碑实现。

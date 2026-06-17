# share_bridge_qq

[![Pub Package](https://img.shields.io/pub/v/share_bridge_qq.svg)](https://pub.dev/packages/share_bridge_qq)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

QQ and QZone sharing capability package for Share Bridge.

## Usage

```dart
await QqShareProvider.setPrivacyGranted(true);

final manager = ShareManager();
await manager.register(
  QqShareProvider(
    appId: 'your_qq_app_id',
    universalLink: 'https://example.com/qq/',
    qqHarmonySigner: (request) async {
      final signed = await requestYourBackendToSign(
        type: request.type,
        shareJson: request.shareJson,
      );
      return QqHarmonyShareSignature(
        type: request.type,
        shareJson: request.shareJson,
        timestamp: signed.timestamp,
        nonce: signed.nonce,
        shareJsonSign: signed.shareJsonSign,
        openId: signed.openId,
      );
    },
  ),
);
```

`setPrivacyGranted(true)` calls the official QQ SDK privacy authorization API. Host apps should call it after users agree to the privacy policy.

`qqHarmonySigner` is used only by QQ HarmonyOS sharing. QQ HarmonyOS SDK requires signing `shareJson + timestamp + nonce`; the signature should be produced by your backend. Android and iOS ignore this parameter.

Installation checks go through `ShareManager`.

```dart
final installed = await manager.isInstalled(ShareClient.qq);
```

## Scope

- QQ and QZone sharing only.
- No login, OAuth, or user profile APIs.
- Android, iOS, and HarmonyOS support QQ friend webpage sharing, QQ friend image sharing, and QZone webpage sharing.
- Pure image sharing to QZone is not part of the MVP capability set.

## Host Setup

Host apps still need to configure the official QQ SDK requirements for each platform: Android activities and schemes, iOS URL schemes and callback forwarding, and HarmonyOS callback schemes plus backend signing.

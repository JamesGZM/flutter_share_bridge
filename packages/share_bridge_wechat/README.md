# share_bridge_wechat

[![Pub Package](https://img.shields.io/pub/v/share_bridge_wechat.svg)](https://pub.dev/packages/share_bridge_wechat)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

WeChat sharing capability package for Share Bridge.

## Status

- Android integrates WeChat OpenSDK and supports webpage and image sharing with `WXEntryActivity` callback handling.
- iOS integrates `WechatOpenSDK-XCFramework` and supports webpage and image sharing with URL scheme and Universal Link callbacks.
- HarmonyOS integrates `share_bridge_wechat_ohos` and supports webpage and image sharing through WeChat OpenSDK.

## Usage

```dart
final manager = ShareManager();
await manager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/wechat/',
  ),
);
```

The WeChat package does not expose `setPrivacyGranted`. Host apps should follow their own privacy compliance flow and register providers or call sharing only after users agree to the app privacy policy.

## Scope

- WeChat sharing only.
- No login, payment, OAuth, or user profile APIs.
- Webpage and image sharing are supported on Android, iOS, and HarmonyOS.

## Android Callback Setup

The host app must provide `wxapi.WXEntryActivity` under its own package name and extend the base class provided by the plugin.

```kotlin
package your.application.id.wxapi

import com.gongziming.share_bridge_wechat.ShareBridgeWechatEntryActivity

class WXEntryActivity : ShareBridgeWechatEntryActivity()
```

Declare it in the host app `AndroidManifest.xml`.

## iOS Callback Setup

Configure URL schemes, `LSApplicationQueriesSchemes`, Associated Domains when Universal Links are used, and forward AppDelegate or SceneDelegate callbacks to `share_bridge_wechat_ios`.

## HarmonyOS Setup

HarmonyOS is loaded through `share_bridge_wechat_ohos`. WeChat HarmonyOS does not need a signing callback; keep using normal `ShareContent.webpage` and `ShareContent.image`.

See the repository setup guides for complete host configuration.

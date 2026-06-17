# share_bridge_wechat

English | [中文](README.md)

The WeChat sharing capability package for Share Bridge.

Current status:

- Android: integrates WeChat OpenSDK and supports webpage / image sharing with `WXEntryActivity` callback handling.
- iOS: integrates `WechatOpenSDK-XCFramework` and supports webpage / image sharing with URL Scheme / Universal Link callbacks.
- HarmonyOS: adds `share_bridge_wechat_ohos` and supports webpage / image sharing through WeChat OpenSDK.

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

The WeChat package does not expose `setPrivacyGranted`. Host apps should follow their own privacy compliance flow and register providers or call sharing only after users agree to the app privacy policy. The plugin does not fake a privacy API that the WeChat SDK does not provide.

## Scope

- WeChat sharing only.
- No login, payment, OAuth, or user profile APIs.

## Android Callback Setup

The host app must provide `wxapi.WXEntryActivity` under its own package name and extend the base class provided by the plugin:

```kotlin
package your.application.id.wxapi

import com.gongziming.share_bridge_wechat.ShareBridgeWechatEntryActivity

class WXEntryActivity : ShareBridgeWechatEntryActivity()
```

Declare it in the host app `AndroidManifest.xml`:

```xml
<activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

## iOS Callback Setup

The host app needs:

- URL Scheme, usually the WeChat AppID.
- Universal Link matching the WeChat Open Platform configuration.
- Associated Domains such as `applinks:example.com`.
- `LSApplicationQueriesSchemes` with at least `weixin`, `wechat`, `weixinULAPI`, and `weixinURLParamsAPI`.

If SceneDelegate is used, forward `scene(_:openURLContexts:)` and `scene(_:continue:)` to the plugin:

```swift
import share_bridge_wechat_ios

if ShareBridgeWechatPlugin.handleOpen(url) {
  return
}

if ShareBridgeWechatPlugin.handleOpenUniversalLink(userActivity) {
  return
}
```

## HarmonyOS Setup

HarmonyOS is loaded through `share_bridge_wechat_ohos`. WeChat HarmonyOS does not need a signing callback; keep using normal `ShareContent.webpage` / `ShareContent.image`.

Host projects still need to complete WeChat Open Platform HarmonyOS configuration. The example app entry module declares the `weixin` and `wxopensdk` query schemes, and the plugin HAR depends on `@tencent/wechat_open_sdk`.

To receive final share results, the host `EntryAbility` must call `ShareBridgeWechatPlugin.handleWant(want)` from `onCreate` / `onNewWant`. The example project already includes this wiring.

# share_bridge_wechat

[English](README_EN.md) | 中文

Share Bridge 的微信分享能力包。

当前状态：

- Android：已接入微信 OpenSDK，可发起网页 / 图片分享并等待 `WXEntryActivity` 回调。
- iOS：已接入 `WechatOpenSDK-XCFramework`，可发起网页 / 图片分享并处理 URL Scheme / Universal Link 回调。
- HarmonyOS：已新增 `share_bridge_wechat_ohos`，可通过微信 OpenSDK 发起网页 / 图片分享。

## 使用形态

```dart
final manager = ShareManager();
await manager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/wechat/',
  ),
);
```

微信插件不暴露 `setPrivacyGranted`。宿主 App 应按自身隐私合规流程，在用户同意隐私政策后再注册 provider 或调用分享；插件不会伪造微信 SDK 不存在的隐私授权 API。

## 范围

- 只做微信分享。
- 不做登录、支付、OAuth、用户资料。

## Android 回调接入

宿主 App 必须在自己的包名下提供 `wxapi.WXEntryActivity`，并继承插件提供的基类：

```kotlin
package your.application.id.wxapi

import com.gongziming.share_bridge_wechat.ShareBridgeWechatEntryActivity

class WXEntryActivity : ShareBridgeWechatEntryActivity()
```

同时需要在宿主 App 的 `AndroidManifest.xml` 中声明：

```xml
<activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

## iOS 回调接入

宿主 App 需要配置：

- URL Scheme：通常为微信 AppID。
- Universal Link：需要和微信开放平台后台一致。
- Associated Domains：形如 `applinks:example.com`。
- `LSApplicationQueriesSchemes`：至少包含 `weixin`、`wechat`、`weixinULAPI`、`weixinURLParamsAPI`。

如果使用 SceneDelegate，需要在 `scene(_:openURLContexts:)` 和 `scene(_:continue:)` 中转发给插件：

```swift
import share_bridge_wechat_ios

if ShareBridgeWechatPlugin.handleOpen(url) {
  return
}

if ShareBridgeWechatPlugin.handleOpenUniversalLink(userActivity) {
  return
}
```

## HarmonyOS 接入

HarmonyOS 平台由 `share_bridge_wechat_ohos` 自动接入。微信 HarmonyOS 不需要签名 callback，继续使用普通 `ShareContent.webpage` / `ShareContent.image`。

宿主工程需要按微信开放平台 HarmonyOS 文档完成应用配置；示例 App 的 entry 模块已声明 `weixin`、`wxopensdk` 查询 scheme，插件 HAR 依赖 `@tencent/wechat_open_sdk`。

为接收分享结果，宿主 `EntryAbility` 需要在 `onCreate` / `onNewWant` 调用 `ShareBridgeWechatPlugin.handleWant(want)`。示例工程已配置。

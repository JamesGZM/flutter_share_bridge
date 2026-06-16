# Android 接入说明

## 微信分享

当前 Android 侧已接入微信 OpenSDK：

```kotlin
implementation("com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0")
```

插件支持：

- `wechat.session` 网页分享。
- `wechat.timeline` 网页分享。
- `wechat.session` 图片分享。
- `wechat.timeline` 图片分享。
- `WXEntryActivity` 回调结果映射。

暂未处理：

- 小程序分享。
- 音乐、视频、文件分享。
- 复杂缩略图策略。

## 宿主 App 配置

### 1. 微信开放平台配置

需要在微信开放平台配置：

- Android 包名。
- Android 应用签名。
- 微信 AppID。

调试时要确保运行包名和签名与开放平台配置一致，否则微信可能返回失败。

### 2. WXEntryActivity

微信要求回调 Activity 位于宿主 App 包名下的 `wxapi.WXEntryActivity`。

宿主 App 新建：

```kotlin
package your.application.id.wxapi

import com.gongziming.share_bridge_wechat.ShareBridgeWechatEntryActivity

class WXEntryActivity : ShareBridgeWechatEntryActivity()
```

并在宿主 App 的 `AndroidManifest.xml` 中声明：

```xml
<activity
    android:name=".wxapi.WXEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

### 3. 包可见性

插件 AAR 已声明：

```xml
<queries>
  <package android:name="com.tencent.mm" />
</queries>
```

如果宿主工程有特殊 manifest 合并规则，需要确认该声明没有被移除。

## 本地调试命令

示例工程支持通过 dart-define 传入微信 AppID：

```sh
cd packages/share_bridge_wechat/example
fvm flutter run --dart-define=WECHAT_APP_ID=你的微信AppID
```

真机调试前请先确认：

- 手机已安装微信。
- 包名、签名、AppID 与微信开放平台一致。
- `WXEntryActivity` 已在最终 APK Manifest 中存在。

## QQ 分享

QQ Android 接入尚未实现。后续会补充：

- QQ 互联 AppID 配置。
- QQ Activity result 回调处理。
- 本地图片分享 FileProvider 配置。
- R8 / ProGuard 规则。

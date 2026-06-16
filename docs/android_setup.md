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

当前 Android 侧已完成 QQ SDK 调用适配，插件已接入你本地下载的 QQ 官方 Lite Jar：

```text
packages/share_bridge_qq/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar
```

QQ 互联官方 Android 文档仍以下载 Android SDK/Jar 的方式说明接入，因此当前不使用不可确认的第三方 Maven 坐标。插件直接编译依赖本地 Jar，并调用：

- `Tencent.createInstance(appId, context, authorities)`
- `Tencent.shareToQQ(activity, bundle, listener)`
- `Tencent.shareToQzone(activity, bundle, listener)`
- `Tencent.onActivityResultData(requestCode, resultCode, data, listener)`

插件支持：

- `qq.friend` 网页分享。
- `qq.friend` 图片分享。
- `qq.qzone` 网页分享。

暂未处理：

- QQ 空间纯图片分享。
- 登录、OAuth、用户资料。
- QQ 小程序、音乐、视频、文件等扩展类型。

### 1. 接入 QQ 官方 Android SDK

插件已经接入 QQ 官方 Android Lite Jar，宿主 App 不需要再额外添加 QQ SDK 依赖。

当前 Jar 来自本地 `sdks/143310b667ece8922594fbe866dabdef.zip`：

```text
open_sdk_3.5.19_r9483ffc7_lite.jar
```

如果后续升级 QQ SDK，需要替换 `packages/share_bridge_qq/android/libs/` 下的 Jar，并重新跑 Android 示例编译。

### 2. 宿主 Manifest 配置

插件 Manifest 已声明 SDK 所需网络权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

宿主 App 仍需要在 `application` 内配置 QQ 回调 Activity：

```xml
<activity
    android:name="com.tencent.tauth.AuthActivity"
    android:noHistory="true"
    android:launchMode="singleTask"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="tencent你的QQAppID" />
    </intent-filter>
</activity>

<activity
    android:name="com.tencent.connect.common.AssistActivity"
    android:configChanges="orientation|keyboardHidden|screenSize"
    android:screenOrientation="behind"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"
    android:exported="false" />
```

`android:scheme` 必须替换成 `tencent` + QQ AppID，例如 AppID 是 `222222`，则写 `tencent222222`。

原因：Flutter 插件依赖可以通过 manifest merge 带入插件自身声明的权限、包可见性等通用配置，但 QQ / 微信开放平台要求的回调 Activity、URL Scheme、包名、签名和 FileProvider authorities 都属于宿主 App 配置。插件 example 只能给出模板，不能替每个宿主 App 自动生成真实 AppID 和签名配置。

### 3. QQ 互联配置

需要在 QQ 互联开放平台配置：

- Android 包名。
- Android 应用签名。
- QQ AppID。

调试时要确保运行包名、签名和 AppID 与开放平台配置一致。

### 4. FileProvider

QQ 官方“分享功能存储权限适配”说明：Android Q 以后，分享图片路径需要具备可读权限；使用 FileProvider 时应通过三参数 `createInstance` 创建 Tencent 实例，authorities 默认格式为 `${applicationId}.fileprovider`。

插件使用的 authorities 固定为：

```text
${applicationId}.fileprovider
```

宿主 App 如果要分享本地图片或本地缩略图，需要在 `AndroidManifest.xml` 中配置同名 FileProvider，并提供可访问的文件路径规则。

### 5. 包可见性

插件 AAR 已声明：

```xml
<queries>
  <package android:name="com.tencent.mobileqq" />
  <package android:name="com.tencent.tim" />
</queries>
```

如果宿主工程有特殊 manifest 合并规则，需要确认该声明没有被移除。

## QQ 本地调试命令

示例工程支持通过 dart-define 传入 QQ AppID：

```sh
cd packages/share_bridge_qq/example
fvm flutter run --dart-define=QQ_APP_ID=你的QQ互联AppID
```

示例工程已经内置 QQ SDK 所需的 `AuthActivity`、`AssistActivity` 和 FileProvider 模板。真机调试前需要把：

```xml
<data android:scheme="tencentyour_qq_app_id" />
```

替换为 `tencent` + 你的 QQ AppID，例如：

```xml
<data android:scheme="tencent222222" />
```

`--dart-define=QQ_APP_ID=...` 只会传给 Dart 层，不会自动改 Android Manifest。

真机调试前请先确认：

- 手机已安装 QQ。
- 插件已接入 QQ 官方 Android Lite Jar。
- 包名、签名、AppID 与 QQ 互联开放平台一致。
- 如果测试图片分享，FileProvider authorities 与 `${applicationId}.fileprovider` 一致。

## 聚合示例

仓库根目录的 `example/` 是真实宿主视角的聚合示例，同时依赖：

- `share_bridge_core`
- `share_bridge_widgets`
- `share_bridge_wechat`
- `share_bridge_qq`

Android 侧已经放入微信 `WXEntryActivity`、QQ `AuthActivity` / `AssistActivity`、QQ FileProvider 模板。真机调试前仍必须替换占位 AppID、配置开放平台包名和签名。

```sh
cd example
fvm flutter run \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

## QQ 参考资料

- [QQ 互联：Android_SDK 使用说明](https://wiki.connect.qq.com/android_sdk%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)
- [QQ 互联：分享消息到 QQ（无需 QQ 登录）](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E6%B6%88%E6%81%AF%E5%88%B0qq%EF%BC%88%E6%97%A0%E9%9C%80qq%E7%99%BB%E5%BD%95%EF%BC%89)
- [QQ 互联：分享到 QQ 空间](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%88%B0qq%E7%A9%BA%E9%97%B4)
- [QQ 互联：分享功能存储权限适配](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%8A%9F%E8%83%BD%E5%AD%98%E5%82%A8%E6%9D%83%E9%99%90%E9%80%82%E9%85%8D)

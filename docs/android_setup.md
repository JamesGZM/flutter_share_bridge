# Android Integration

English | [中文](android_setup_CN.md)

## WeChat Sharing

The Android implementation integrates WeChat OpenSDK:

```kotlin
implementation("com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0")
```

Supported:

- `wechat.session` webpage sharing.
- `wechat.timeline` webpage sharing.
- `wechat.session` image sharing.
- `wechat.timeline` image sharing.
- `WXEntryActivity` callback result mapping.

Not handled yet:

- Mini Program sharing.
- Music, video, file, and other extended content types.
- Advanced thumbnail strategies.

## Host App Configuration

### 1. WeChat Open Platform

Configure these values in the WeChat Open Platform:

- Android package name.
- Android app signature.
- WeChat AppID.

During debugging, the runtime package name, signature, and AppID must match the Open Platform configuration.

### 2. WXEntryActivity

WeChat requires the callback Activity to be placed at `wxapi.WXEntryActivity` under the host app package.

Create this class in the host app:

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

### 3. Package Visibility

The plugin AAR declares:

```xml
<queries>
  <package android:name="com.tencent.mm" />
</queries>
```

If the host project has custom manifest merge rules, confirm this declaration is not removed.

## Local Debugging

The example supports passing the WeChat AppID with `dart-define`:

```sh
cd packages/share_bridge_wechat/example
flutter run --dart-define=WECHAT_APP_ID=your_wechat_app_id
```

Before testing on a real device, confirm:

- WeChat is installed.
- Package name, signature, and AppID match the WeChat Open Platform configuration.
- `WXEntryActivity` exists in the final APK manifest.

## QQ Sharing

The Android implementation adapts the QQ SDK calls and uses the official QQ Lite Jar downloaded locally:

```text
packages/share_bridge_qq_android/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar
```

The official QQ Connect Android documentation still describes SDK/Jar download based integration, so this project does not rely on an unverified third-party Maven coordinate. The plugin compiles against the local Jar and calls:

- `Tencent.createInstance(appId, context, authorities)`
- `Tencent.shareToQQ(activity, bundle, listener)`
- `Tencent.shareToQzone(activity, bundle, listener)`
- `Tencent.onActivityResultData(requestCode, resultCode, data, listener)`

Supported:

- `qq.friend` webpage sharing.
- `qq.friend` image sharing.
- `qq.qzone` webpage sharing.

Not handled yet:

- Pure image sharing to QZone.
- Login, OAuth, and user profile APIs.
- QQ Mini Program, music, video, file, and other extended content types.

### 1. QQ Android SDK

The plugin already integrates the official QQ Android Lite Jar. Host apps do not need to add another QQ SDK dependency.

The current Jar comes from local `sdks/143310b667ece8922594fbe866dabdef.zip`:

```text
open_sdk_3.5.19_r9483ffc7_lite.jar
```

To upgrade the QQ SDK later, replace the Jar under `packages/share_bridge_qq_android/android/libs/` and rebuild the Android example.

### 2. Host Manifest

The plugin manifest already declares the SDK network permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

The host app still needs QQ callback activities inside `application`:

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
        <data android:scheme="tencentyour_qq_app_id" />
    </intent-filter>
</activity>

<activity
    android:name="com.tencent.connect.common.AssistActivity"
    android:configChanges="orientation|keyboardHidden|screenSize"
    android:screenOrientation="behind"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"
    android:exported="false" />
```

Replace `android:scheme` with `tencent` + QQ AppID. For example, AppID `222222` becomes `tencent222222`.

Flutter plugin dependencies can merge plugin permissions and package visibility declarations, but QQ / WeChat callback activities, URL schemes, package names, signatures, and FileProvider authorities belong to each host app. The examples can provide templates only.

### 3. QQ Connect Configuration

Configure these values in QQ Connect:

- Android package name.
- Android app signature.
- QQ AppID.

During debugging, package name, signature, and AppID must match the Open Platform configuration.

### 4. FileProvider

QQ's storage permission adaptation notes require readable paths for image sharing on Android Q and later. When using FileProvider, create the Tencent instance with the three-argument `createInstance`; the default authorities format is `${applicationId}.fileprovider`.

The plugin uses this authorities value:

```text
${applicationId}.fileprovider
```

If the host app shares local images or thumbnails, configure a FileProvider with the same authorities and accessible file path rules in `AndroidManifest.xml`.

### 5. Package Visibility

The plugin AAR declares:

```xml
<queries>
  <package android:name="com.tencent.mobileqq" />
  <package android:name="com.tencent.tim" />
</queries>
```

If the host project has custom manifest merge rules, confirm this declaration is not removed.

## QQ Local Debugging

The example supports passing the QQ AppID with `dart-define`:

```sh
cd packages/share_bridge_qq/example
flutter run --dart-define=QQ_APP_ID=your_qq_app_id
```

The example includes templates for `AuthActivity`, `AssistActivity`, and FileProvider. Before real-device debugging, replace:

```xml
<data android:scheme="tencentyour_qq_app_id" />
```

with `tencent` + your QQ AppID, for example:

```xml
<data android:scheme="tencent222222" />
```

`--dart-define=QQ_APP_ID=...` is only passed to Dart. It does not modify the Android Manifest.

# share_bridge_qq

English | [中文](README.md)

The QQ and QZone sharing capability package for Share Bridge.

Current status:

- Android supports native QQ / QZone sharing calls.
- Android integrates the local official SDK: `../share_bridge_qq_android/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`.
- iOS supports native QQ / QZone sharing calls.
- iOS integrates the local official SDK: `../share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework`.

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

`setPrivacyGranted(true)` calls the official QQ SDK privacy authorization API: Android uses `Tencent.setIsPermissionGranted(true)`, and iOS uses `TencentOAuth.setIsUserAgreedAuthorization(true)`. Host apps should call it after users agree to the privacy policy.

`qqHarmonySigner` is used only by QQ HarmonyOS sharing. QQ HarmonyOS SDK requires signing `shareJson + timestamp + nonce`; the signature should be produced by your backend. Android and iOS ignore this parameter.

Installation checks go through the manager:

```dart
final installed = await manager.isInstalled(ShareClient.qq);
```

For local debugging, pass the AppID to the example:

```sh
cd packages/share_bridge_qq/example
fvm flutter run --dart-define=QQ_APP_ID=your_qq_app_id
```

Before Android real-device debugging, replace `tencentyour_qq_app_id` in the example `AndroidManifest.xml` with `tencent` + your QQ AppID. `--dart-define` is only passed to Dart and does not modify the Manifest scheme.

## Scope

- QQ / QZone sharing only.
- No login, OAuth, or user profile APIs.
- Android supports QQ friend webpage sharing, QQ friend image sharing, and QZone webpage sharing.
- iOS supports QQ friend webpage sharing, QQ friend image sharing, and QZone webpage sharing.
- HarmonyOS supports QQ friend webpage sharing, QQ friend image sharing, and QZone webpage sharing; it requires `qqHarmonySigner`.
- Pure image sharing to QZone is not part of the MVP capability set on Android / iOS / HarmonyOS.

## Android SDK Integration

The official QQ Connect Android SDK documentation still describes SDK/Jar download based integration. This plugin uses the official Lite Jar downloaded locally:

```text
../share_bridge_qq_android/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar
```

The plugin compiles directly against that Jar and uses:

- `com.tencent.tauth.Tencent`
- `com.tencent.tauth.IUiListener`
- `com.tencent.connect.share.QQShare`
- `com.tencent.connect.share.QzoneShare`

During initialization, the plugin first calls:

```kotlin
Tencent.createInstance(appId, context, "${applicationId}.fileprovider")
```

Host apps do not need to add another QQ SDK dependency, but they still need to configure `AuthActivity`, `AssistActivity`, and the `tencent{AppID}` scheme according to QQ Connect Android SDK documentation.

When sharing local images or thumbnails, host apps also need to configure FileProvider according to QQ's storage permission adaptation notes, with authorities matching `${applicationId}.fileprovider`. Full setup is documented in the root `docs/android_setup.md`.

References:

- [QQ Connect: Android SDK guide](https://wiki.connect.qq.com/android_sdk%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)
- [QQ Connect: Share messages to QQ without QQ login](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E6%B6%88%E6%81%AF%E5%88%B0qq%EF%BC%88%E6%97%A0%E9%9C%80qq%E7%99%BB%E5%BD%95%EF%BC%89)
- [QQ Connect: Share to QZone](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%88%B0qq%E7%A9%BA%E9%97%B4)
- [QQ Connect: Sharing storage permission adaptation](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%8A%9F%E8%83%BD%E5%AD%98%E5%82%A8%E6%9D%83%E9%99%90%E9%80%82%E9%85%8D)

## iOS SDK Integration

The QQ Connect iOS SDK uses the official Lite XCFramework downloaded locally:

```text
../share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework
```

The plugin compiles directly against that XCFramework and uses:

- `TencentOAuth`
- `QQApiInterface`
- `QQApiURLObject`
- `QQApiImageObject`
- `SendMessageToQQReq`

Host apps do not need to add another QQ iOS SDK dependency, but they still need to configure:

- `CFBundleURLTypes`, with scheme `tencent{QQAppID}`.
- `LSApplicationQueriesSchemes`.
- SceneDelegate / AppDelegate callback forwarding.
- Associated Domains if Universal Link is enabled.

Full setup is documented in the root `docs/ios_setup.md`.

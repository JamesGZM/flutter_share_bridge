# share_bridge_qq

[English](README_EN.md) | 中文

Share Bridge 的 QQ 与 QQ 空间分享能力包。

当前状态：

- Android 已完成 QQ / QQ 空间分享的原生调用适配。
- Android 侧已接入本地官方 SDK：`../share_bridge_qq_android/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`。
- iOS 已完成 QQ / QQ 空间分享的原生调用适配。
- iOS 侧已接入本地官方 SDK：`../share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework`。

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

`setPrivacyGranted(true)` 会真实调用 QQ 官方 SDK 隐私授权 API：Android 对应 `Tencent.setIsPermissionGranted(true)`，iOS 对应 `TencentOAuth.setIsUserAgreedAuthorization(true)`。宿主 App 应在用户同意隐私政策后调用它。

安装检查统一走 manager：

```dart
final installed = await manager.isInstalled(ShareClient.qq);
```

本地调试可以通过示例工程传入 AppID：

```sh
cd packages/share_bridge_qq/example
fvm flutter run --dart-define=QQ_APP_ID=你的QQ互联AppID
```

Android 真机调试前，还需要把 example 的 `AndroidManifest.xml` 中 `tencentyour_qq_app_id` 替换成 `tencent` + 你的 QQ AppID。`--dart-define` 只传给 Dart 层，不会自动修改 Manifest scheme。

## 范围

- 只做 QQ / QQ 空间分享。
- 不做登录、OAuth、用户资料。
- Android 支持 QQ 好友网页分享、QQ 好友图片分享、QQ 空间网页分享。
- iOS 支持 QQ 好友网页分享、QQ 好友图片分享、QQ 空间网页分享。
- Android / iOS 暂不把 QQ 空间纯图片分享作为 MVP 能力。

## Android SDK 接入说明

QQ 互联 Android SDK 当前官方文档仍以下载 SDK/Jar 的方式说明接入。当前插件使用你本地下载的官方 Lite Jar：

```text
../share_bridge_qq_android/android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar
```

插件已经直接编译依赖该 Jar，并使用：

- `com.tencent.tauth.Tencent`
- `com.tencent.tauth.IUiListener`
- `com.tencent.connect.share.QQShare`
- `com.tencent.connect.share.QzoneShare`

插件初始化时会优先调用：

```kotlin
Tencent.createInstance(appId, context, "${applicationId}.fileprovider")
```

宿主 App 不需要再单独添加 QQ SDK 依赖，但仍需要按 QQ 互联 Android SDK 文档配置 `AuthActivity`、`AssistActivity` 和 `tencent{AppID}` scheme。

涉及本地图片、缩略图分享时，宿主 App 还需要按 QQ 官方“分享功能存储权限适配”配置 FileProvider，并让 authorities 与 `${applicationId}.fileprovider` 一致。完整配置见仓库根目录的 `docs/android_setup.md`。

参考资料：

- [QQ 互联：Android_SDK 使用说明](https://wiki.connect.qq.com/android_sdk%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E)
- [QQ 互联：分享消息到 QQ（无需 QQ 登录）](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E6%B6%88%E6%81%AF%E5%88%B0qq%EF%BC%88%E6%97%A0%E9%9C%80qq%E7%99%BB%E5%BD%95%EF%BC%89)
- [QQ 互联：分享到 QQ 空间](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%88%B0qq%E7%A9%BA%E9%97%B4)
- [QQ 互联：分享功能存储权限适配](https://wiki.connect.qq.com/%E5%88%86%E4%BA%AB%E5%8A%9F%E8%83%BD%E5%AD%98%E5%82%A8%E6%9D%83%E9%99%90%E9%80%82%E9%85%8D)

## iOS SDK 接入说明

QQ 互联 iOS SDK 当前使用你本地下载的官方 Lite XCFramework：

```text
../share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework
```

插件已经直接编译依赖该 XCFramework，并使用：

- `TencentOAuth`
- `QQApiInterface`
- `QQApiURLObject`
- `QQApiImageObject`
- `SendMessageToQQReq`

宿主 App 不需要再单独添加 QQ iOS SDK 依赖，但仍需要配置：

- `CFBundleURLTypes`，scheme 为 `tencent{QQAppID}`。
- `LSApplicationQueriesSchemes`。
- SceneDelegate / AppDelegate 回调转发。
- 如启用 Universal Link，还需要配置 Associated Domains。

完整配置见仓库根目录的 `docs/ios_setup.md`。

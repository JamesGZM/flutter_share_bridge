# Flutter Share Bridge

[![Core](https://img.shields.io/pub/v/share_bridge_core.svg?label=share_bridge_core)](https://pub.dev/packages/share_bridge_core)
[![WeChat](https://img.shields.io/pub/v/share_bridge_wechat.svg?label=share_bridge_wechat)](https://pub.dev/packages/share_bridge_wechat)
[![QQ](https://img.shields.io/pub/v/share_bridge_qq.svg?label=share_bridge_qq)](https://pub.dev/packages/share_bridge_qq)
[![Widgets](https://img.shields.io/pub/v/share_bridge_widgets.svg?label=share_bridge_widgets)](https://pub.dev/packages/share_bridge_widgets)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[English](README.md) | 中文

Flutter Share Bridge 是一组模块化的 Flutter 社交分享插件，用于把内容分享到微信、QQ 和 QQ 空间。

这个项目只做分享，不包含登录、支付、OAuth 或用户资料能力。你可以只接入需要的平台包，也可以额外使用 `share_bridge_widgets` 提供的分享面板 UI。

## 功能

- 微信好友、微信朋友圈分享
- QQ 好友、QQ 空间分享
- 网页分享
- 图片分享
- 统一的 Dart 分享结果 `ShareResult`
- 统一的分享入口 `ShareManager`
- 可选 Flutter 分享面板 UI
- Android / iOS / HarmonyOS 官方 SDK 接入

## 包

| 包 | 说明 |
| --- | --- |
| `share_bridge_core` | 核心模型、分享管理器、结果类型，不依赖 Flutter |
| `share_bridge_wechat` | 微信分享主包，自动带入 Android / iOS / HarmonyOS 实现 |
| `share_bridge_qq` | QQ / QQ 空间分享主包，自动带入 Android / iOS / HarmonyOS 实现 |
| `share_bridge_widgets` | 可选分享 UI |

平台实现包采用 federated plugin 结构拆分：

```text
share_bridge_platform_interface
share_bridge_wechat_android
share_bridge_wechat_ios
share_bridge_wechat_ohos
share_bridge_qq_android
share_bridge_qq_ios
share_bridge_qq_ohos
```

普通宿主 App 只需要依赖主包；平台实现包由 `default_package` 自动带入。

## 安装

包已经发布到 pub.dev，宿主项目可以按需添加：

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.2
  share_bridge_wechat: ^0.1.0-dev.2
  share_bridge_qq: ^0.1.0-dev.2
  share_bridge_widgets: ^0.1.0-dev.2
```

## 快速开始

```dart
final manager = ShareManager();

// QQ 官方 SDK 要求宿主在用户同意隐私政策后声明授权。
await QqShareProvider.setPrivacyGranted(true);

await manager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/wechat/',
  ),
);

await manager.register(
  QqShareProvider(
    appId: 'your_qq_app_id',
    universalLink: 'https://example.com/qq/',
  ),
);

final result = await manager.share(
  channel: ShareChannel.wechatSession,
  content: const ShareContent.webpage(
    title: '标题',
    description: '描述',
    url: 'https://example.com',
  ),
);

if (result.isSuccess) {
  // 分享成功
}
```

`ShareManager.register()` 会立即初始化对应 SDK。请在用户同意隐私政策、并完成宿主平台配置后再注册 provider。

## 检查客户端是否安装

`ShareClient` 表示真实 App，`ShareChannel` 表示分享目标。

```dart
final wechatInstalled = await manager.isInstalled(ShareClient.wechat);
final qqInstalled = await manager.isInstalled(ShareClient.qq);
```

分享时不需要业务方提前判断安装状态。`ShareManager.share()` 内部会处理未安装情况，并返回 `ShareResultCode.appNotInstalled`。

## 图片分享

图片来源只支持本地文件和内存字节。

```dart
final result = await manager.share(
  channel: ShareChannel.qqFriend,
  content: const ShareContent.image(
    image: ShareImageSource.file('/path/to/image.png'),
    thumbnail: ShareImageSource.file('/path/to/thumb.png'),
  ),
);
```

网络图片、Flutter asset、缓存策略和鉴权下载由宿主 App 自行处理。处理完成后，传入本地文件路径或 `Uint8List`。

## 分享面板

```dart
final result = await ShareBridgeSheet.show(
  context: context,
  manager: manager,
  content: const ShareContent.webpage(
    title: '标题',
    description: '描述',
    url: 'https://example.com',
  ),
);
```

`share_bridge_widgets` 只依赖 `share_bridge_core`，不绑定微信或 QQ 插件。

## 平台配置

插件已经接入对应官方 SDK，但宿主 App 仍必须按开放平台要求配置包名、签名、URL Scheme、Universal Link、回调 Activity / AppDelegate 等信息。

Android：

- 微信需要宿主提供 `${applicationId}.wxapi.WXEntryActivity`
- QQ 需要配置 `AuthActivity`、`AssistActivity` 和 `tencent{QQAppID}` scheme
- 图片分享需要 FileProvider，authorities 使用 `${applicationId}.fileprovider`
- Android 11+ 需要配置包可见性 `queries`

iOS：

- 配置 URL Scheme
- 配置 `LSApplicationQueriesSchemes`
- 如使用 Universal Link，配置 Associated Domains
- 在 AppDelegate / SceneDelegate 中转发微信和 QQ 回调

HarmonyOS：

- 普通宿主 App 依赖 `share_bridge_wechat` / `share_bridge_qq` 即可，`share_bridge_wechat_ohos` / `share_bridge_qq_ohos` 由 `default_package` 自动带入。
- 微信需要配置 `querySchemes`，并在 `EntryAbility.onCreate/onNewWant` 调用 `ShareBridgeWechatPlugin.handleWant(want)` 接收分享结果。
- QQ 需要配置 `qqopenapi` 回调 scheme，并开启 `useNormalizedOHMUrl`。
- QQ HarmonyOS 分享需要业务后台签名，通过 `QqShareProvider(qqHarmonySigner: ...)` 接入。
- 调试前需要用 DevEco Studio 为 `ohos` 工程生成本机调试签名；证书、keystore、`local.properties` 不提交。

详细说明：

- [Android 配置](docs/android_setup.md)
- [iOS 配置](docs/ios_setup.md)
- [HarmonyOS 配置](docs/harmonyos_setup.md)
- [隐私说明](docs/privacy.md)

## 本地示例

```sh
cd example
flutter run \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

HarmonyOS 本地调试：

```sh
cd example
flutter run -d <device-id> \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

`dart-define` 只传给 Dart 层，不会自动修改 AndroidManifest、Info.plist、HarmonyOS `module.json5` 或开放平台后台配置。

## 错误处理

所有分享结果都会归一为 `ShareResult`：

```dart
switch (result.code) {
  case ShareResultCode.success:
    break;
  case ShareResultCode.cancelled:
    break;
  case ShareResultCode.appNotInstalled:
    break;
  case ShareResultCode.permissionDenied:
    break;
  default:
    break;
}
```

常见错误：

| 错误码 | 含义 |
| --- | --- |
| `appNotInstalled` | 目标 App 未安装 |
| `configError` | AppID、URL Scheme、Manifest、Info.plist 等配置错误 |
| `permissionDenied` | 隐私授权或 SDK 权限要求未满足 |
| `unsupportedChannel` | 当前 provider 不支持该分享目标 |
| `unsupportedContent` | 当前平台不支持该内容类型 |
| `busy` | 上一个分享请求还在等待回调 |

## 开发检查

```sh
cd packages/share_bridge_core && dart analyze && dart test
cd packages/share_bridge_widgets && flutter analyze && flutter test
cd packages/share_bridge_platform_interface && flutter analyze && flutter test
cd packages/share_bridge_wechat_ohos && flutter analyze && flutter test
cd packages/share_bridge_qq_ohos && flutter analyze && flutter test
cd packages/share_bridge_wechat && flutter analyze && flutter test
cd packages/share_bridge_qq && flutter analyze && flutter test
cd packages/share_bridge_wechat_android && flutter analyze
cd packages/share_bridge_wechat_ios && flutter analyze
cd packages/share_bridge_qq_android && flutter analyze
cd packages/share_bridge_qq_ios && flutter analyze
```

原生构建：

```sh
cd example && flutter build apk --debug
cd example && flutter build ios --debug --no-codesign
```

## pub.dev 包

- [share_bridge_core](https://pub.dev/packages/share_bridge_core)
- [share_bridge_wechat](https://pub.dev/packages/share_bridge_wechat)
- [share_bridge_qq](https://pub.dev/packages/share_bridge_qq)
- [share_bridge_widgets](https://pub.dev/packages/share_bridge_widgets)

## 设计原则

`register()` 即初始化，`share()` 只负责分享调度和错误归一。这一点接近 `fluwx`、`tencent_kit` 这类 SDK 包的使用方式；`share_plus` 是系统分享面板封装，不适合作为微信 / QQ SDK 初始化模型参考。

# Flutter Share Bridge

[![Core](https://img.shields.io/pub/v/share_bridge_core.svg?label=share_bridge_core)](https://pub.dev/packages/share_bridge_core)
[![WeChat](https://img.shields.io/pub/v/share_bridge_wechat.svg?label=share_bridge_wechat)](https://pub.dev/packages/share_bridge_wechat)
[![QQ](https://img.shields.io/pub/v/share_bridge_qq.svg?label=share_bridge_qq)](https://pub.dev/packages/share_bridge_qq)
[![Widgets](https://img.shields.io/pub/v/share_bridge_widgets.svg?label=share_bridge_widgets)](https://pub.dev/packages/share_bridge_widgets)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

Flutter Share Bridge is a modular Flutter social sharing plugin set for sharing content to WeChat, QQ, and QZone.

It is share-only. It does not include login, payment, OAuth, or user profile APIs. You can depend on only the platform packages you need, and optionally use `share_bridge_widgets` for a Flutter share sheet UI.

## Features

- Share to WeChat session and WeChat timeline
- Share to QQ friend and QZone
- Webpage sharing
- Image sharing
- Unified Dart result type: `ShareResult`
- Unified dispatcher: `ShareManager`
- Optional Flutter share UI
- Official SDK integration on Android / iOS / HarmonyOS

## Packages

| Package | Description |
| --- | --- |
| `share_bridge_core` | Core models, share manager, result types. No Flutter dependency |
| `share_bridge_wechat` | WeChat sharing wrapper package, automatically endorses Android / iOS / HarmonyOS implementations |
| `share_bridge_qq` | QQ / QZone sharing wrapper package, automatically endorses Android / iOS / HarmonyOS implementations |
| `share_bridge_widgets` | Optional share UI |

Platform implementations use the federated plugin layout:

```text
share_bridge_platform_interface
share_bridge_wechat_android
share_bridge_wechat_ios
share_bridge_wechat_ohos
share_bridge_qq_android
share_bridge_qq_ios
share_bridge_qq_ohos
```

Host apps should depend on the wrapper packages. Platform packages are pulled in by `default_package`.

## Installation

Packages are published on pub.dev. Host apps can depend on the packages they need:

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.2
  share_bridge_wechat: ^0.1.0-dev.2
  share_bridge_qq: ^0.1.0-dev.2
  share_bridge_widgets: ^0.1.0-dev.2
```

## Quick Start

```dart
final manager = ShareManager();

// The QQ SDK requires the host app to declare privacy consent after the user agrees.
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
    title: 'Title',
    description: 'Description',
    url: 'https://example.com',
  ),
);

if (result.isSuccess) {
  // Shared successfully.
}
```

`ShareManager.register()` initializes the provider immediately. Register providers only after the user has accepted your privacy policy and the host platform configuration is ready.

## Check Installation

`ShareClient` represents a real client app. `ShareChannel` represents a share destination.

```dart
final wechatInstalled = await manager.isInstalled(ShareClient.wechat);
final qqInstalled = await manager.isInstalled(ShareClient.qq);
```

You do not have to check installation before sharing. `ShareManager.share()` handles that internally and returns `ShareResultCode.appNotInstalled` when needed.

## Image Sharing

Images support local files and in-memory bytes only.

```dart
final result = await manager.share(
  channel: ShareChannel.qqFriend,
  content: const ShareContent.image(
    image: ShareImageSource.file('/path/to/image.png'),
    thumbnail: ShareImageSource.file('/path/to/thumb.png'),
  ),
);
```

Network images, Flutter assets, caching, and authenticated downloads should be handled by the host app. Pass a local file path or `Uint8List` after conversion.

## Share Sheet

```dart
final result = await ShareBridgeSheet.show(
  context: context,
  manager: manager,
  content: const ShareContent.webpage(
    title: 'Title',
    description: 'Description',
    url: 'https://example.com',
  ),
);
```

`share_bridge_widgets` depends only on `share_bridge_core`. It does not depend on the WeChat or QQ plugins.

## Platform Setup

The plugins include official SDK integrations, but the host app must still complete the platform setup required by each developer platform.

Android:

- WeChat requires `${applicationId}.wxapi.WXEntryActivity`
- QQ requires `AuthActivity`, `AssistActivity`, and the `tencent{QQAppID}` scheme
- Image sharing requires a FileProvider with authorities `${applicationId}.fileprovider`
- Android 11+ requires package visibility `queries`

iOS:

- Configure URL schemes
- Configure `LSApplicationQueriesSchemes`
- Configure Associated Domains if Universal Links are used
- Forward WeChat and QQ callbacks from AppDelegate / SceneDelegate

HarmonyOS:

- Host apps normally depend on `share_bridge_wechat` / `share_bridge_qq`; `share_bridge_wechat_ohos` / `share_bridge_qq_ohos` are pulled in by `default_package`.
- WeChat requires query schemes and forwarding `EntryAbility.onCreate/onNewWant` to `ShareBridgeWechatPlugin.handleWant(want)` so final share results can be received.
- QQ requires the `qqopenapi` callback scheme and `useNormalizedOHMUrl`.
- QQ HarmonyOS sharing requires backend signing through `QqShareProvider(qqHarmonySigner: ...)`.
- Before debugging, generate a local debug signing config for the `ohos` project in DevEco Studio. Certificates, keystores, and `local.properties` are not committed.

See:

- [Android setup](docs/android_setup.md)
- [iOS setup](docs/ios_setup.md)
- [HarmonyOS setup](docs/harmonyos_setup_EN.md)
- [Privacy notes](docs/privacy.md)

## Local Example

```sh
cd example
flutter run \
  --dart-define=WECHAT_APP_ID=your_wechat_app_id \
  --dart-define=QQ_APP_ID=your_qq_app_id
```

HarmonyOS local debugging:

```sh
cd example
flutter run -d <device-id> \
  --dart-define=WECHAT_APP_ID=your_wechat_app_id \
  --dart-define=QQ_APP_ID=your_qq_app_id
```

`dart-define` only passes values to Dart code. It does not update AndroidManifest, Info.plist, HarmonyOS `module.json5`, or developer console settings.

## Error Handling

All share operations return a normalized `ShareResult`:

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

Common result codes:

| Code | Meaning |
| --- | --- |
| `appNotInstalled` | Target app is not installed |
| `configError` | AppID, URL scheme, AndroidManifest, Info.plist, or related setup is incorrect |
| `permissionDenied` | Privacy consent or SDK permission requirement is not satisfied |
| `unsupportedChannel` | The provider does not support the target channel |
| `unsupportedContent` | The platform does not support the content type |
| `busy` | A previous share request is still waiting for callback |

## Development Checks

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

Native builds:

```sh
cd example && flutter build apk --debug
cd example && flutter build ios --debug --no-codesign
```

## Packages on pub.dev

- [share_bridge_core](https://pub.dev/packages/share_bridge_core)
- [share_bridge_wechat](https://pub.dev/packages/share_bridge_wechat)
- [share_bridge_qq](https://pub.dev/packages/share_bridge_qq)
- [share_bridge_widgets](https://pub.dev/packages/share_bridge_widgets)

Before publishing:

- Verify Android / iOS callbacks on real devices
- Run pub.dev dry-run checks
- Switch internal package dependencies to hosted versions
- Complete platform setup and troubleshooting docs

## Design Principle

`register()` initializes the SDK, and `share()` dispatches share requests and normalizes errors. This is closer to SDK wrappers such as `fluwx` and `tencent_kit`. `share_plus` wraps the system share sheet and is not a good model for WeChat / QQ SDK initialization.

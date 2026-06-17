# 发布检查清单

[English](release_EN.md) | 中文

当前开发阶段优先使用本地 `path` 依赖，保证 monorepo 内联调简单直接。

## 当前 dry-run 结果

已验证：

- `share_bridge_core`：`dart pub publish --dry-run` 通过，0 warnings。
- `share_bridge_widgets`：dry-run 阻塞于 `share_bridge_core` 本地 `path` 依赖。
- `share_bridge_wechat`：dry-run 阻塞于 `share_bridge_core` 本地 `path` 依赖。
- `share_bridge_qq`：dry-run 阻塞于 `share_bridge_core` 本地 `path` 依赖。

这个阻塞符合当前本地调试策略，不应在本地联调阶段提前切换 hosted 依赖。

## 发布顺序

发布前再做以下调整：

- 先发布 `share_bridge_core`。
- 从四个 package 的 `pubspec.yaml` 中移除 `publish_to: none`。
- 将各包中的本地 `path` 依赖改为 pub 版本约束，例如：

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.1
```

- 发布 `share_bridge_widgets`。
- 发布 `share_bridge_wechat`。
- 发布 `share_bridge_qq`。
  federated 平台包应先发布 `*_platform_interface`、`*_android`、`*_ios`，再发布主包。

## 每包发布前命令

`share_bridge_core`：

```sh
cd packages/share_bridge_core
dart analyze
dart test
dart pub publish --dry-run
```

Flutter 包：

```sh
cd packages/share_bridge_widgets
flutter analyze
flutter test
flutter pub publish --dry-run

cd packages/share_bridge_wechat
flutter analyze
flutter test
flutter pub publish --dry-run

cd packages/share_bridge_qq
flutter analyze
flutter test
flutter pub publish --dry-run
```

原生插件额外编译示例：

```sh
cd packages/share_bridge_wechat/example
flutter build apk --debug
flutter build ios --debug --no-codesign

cd packages/share_bridge_qq/example
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## SDK 与许可确认

- `share_bridge_wechat` Android 使用 `com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0`。
- `share_bridge_wechat` iOS 使用 `WechatOpenSDK-XCFramework`, `2.0.5`。
- `share_bridge_qq_android` Android 内置 `android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`。
- `share_bridge_qq_ios` iOS 内置 `ios/Frameworks/TencentOpenAPI.xcframework`。
- 发布 `share_bridge_qq` 前必须确认 QQ SDK 允许随 pub 包再分发；如果许可不允许，需要改成用户本地放置 SDK 的接入方式。

## 其他检查

- 按顺序运行每个包的测试、分析和 `pub publish --dry-run`。
- 在 pub.dev 检查包名是否可用。
- 记录 Flutter、Dart、Android Gradle Plugin、Kotlin、Xcode、微信 SDK、QQ SDK 版本。
- 确认每个 README 与实际已实现能力一致。
- 确认隐私说明与官方 SDK 要求一致。

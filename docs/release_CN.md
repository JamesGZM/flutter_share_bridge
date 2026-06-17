# 发布说明

[English](release.md) | 中文

当前已发布到 pub.dev 的版本是 `0.1.0-dev.4`。

## 已发布包

按依赖顺序发布：

1. `share_bridge_core`
2. `share_bridge_platform_interface`
3. `share_bridge_wechat_android`
4. `share_bridge_wechat_ios`
5. `share_bridge_wechat_ohos`
6. `share_bridge_qq_android`
7. `share_bridge_qq_ios`
8. `share_bridge_qq_ohos`
9. `share_bridge_wechat`
10. `share_bridge_qq`
11. `share_bridge_widgets`

## 发布前检查

```sh
cd packages/share_bridge_core
dart analyze
dart test
dart pub publish --dry-run
```

Flutter 包：

```sh
flutter analyze
flutter test
dart pub publish --dry-run
```

如果某个包没有 `*_test.dart`，只运行 `flutter analyze` 和 `dart pub publish --dry-run`。

## 发布流程

1. 本轮发布先确定一个统一版本号。
2. 更新所有 `packages/*/pubspec.yaml` 的 `version`。
3. 所有内部 package 依赖约束同步到同一版本范围。
4. 根 README、包 README、设计文档中的安装示例同步到新版本。
5. 每个 package 的 `CHANGELOG.md` 增加本次版本条目。
6. 对每个 package 跑 analyze、测试和 `dart pub publish --dry-run`。
7. 按依赖顺序执行 `dart pub publish --force`。
8. 发布后等待 pub.dev 索引完成，再复查页面信息。

## 当前发布验证

- `0.1.0-dev.4` 的 11 个包均已成功上传到 pub.dev。
- 所有包 `dart pub publish --dry-run` / `flutter pub publish --dry-run` 为 0 warnings。
- 本次发布包含 QQ Android、QQ iOS、QQ HarmonyOS、微信 HarmonyOS 的 SDK 回调链加固。
- 根 README 和包 README 默认使用英文，并提供 `README_CN.md` 中文入口。
- `pubspec.yaml` 已包含 `homepage`、monorepo 子路径 `repository`、`issue_tracker`、`topics`。
- Android / iOS 相关包已声明 pub.dev 支持的顶层 `platforms`。
- HarmonyOS 包未伪造 pub.dev 不支持的 `ohos` 顶层平台。

## 分数说明

已处理的可合理补分项：

- README / CHANGELOG / LICENSE。
- repository / homepage / issue tracker。
- package description 长度。
- public API dartdoc 覆盖率。
- Android / iOS 平台标识。

没有为了分数强行处理的项：

- 不给 HarmonyOS 包伪造 Android / iOS / Web 平台。
- 不给 wrapper 包伪造 Web / Windows / macOS / Linux 支持。
- 不给每个 federated implementation 包复制完整 example 工程。
- iOS Swift Package Manager 支持后续单独评估，确认原生 SDK 结构可行后再补。

## SDK 与许可确认

- `share_bridge_wechat_android` 使用 `com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0`。
- `share_bridge_wechat_ios` 使用 `WechatOpenSDK-XCFramework`。
- `share_bridge_wechat_ohos` 使用 `@tencent/wechat_open_sdk`。
- `share_bridge_qq_android` 内置 `android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`。
- `share_bridge_qq_ios` 内置 `ios/Frameworks/TencentOpenAPI.xcframework`。
- `share_bridge_qq_ohos` 使用 `@tencent/qq-open-sdk`。

后续如果 QQ SDK 再分发许可有变化，应改成宿主本地放置 SDK 的接入方式。

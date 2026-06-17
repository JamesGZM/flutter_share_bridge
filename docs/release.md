# Release Notes

English | [中文](release_CN.md)

The current published version on pub.dev is `0.1.0-dev.4`.

## Published Packages

Published in dependency order:

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

## Pre-Publish Checks

```sh
cd packages/share_bridge_core
dart analyze
dart test
dart pub publish --dry-run
```

Flutter packages:

```sh
flutter analyze
flutter test
dart pub publish --dry-run
```

If a package has no `*_test.dart` files, run only `flutter analyze` and
`dart pub publish --dry-run`.

## Publish Procedure

1. Pick one version for all packages in the release train.
2. Update every `packages/*/pubspec.yaml` `version`.
3. Update all internal package constraints to the same version range.
4. Update install snippets in root README, package README files, and design docs.
5. Add a `CHANGELOG.md` entry for every package.
6. Run analyze, tests, and `dart pub publish --dry-run` for every package.
7. Publish in dependency order with `dart pub publish --force`.
8. Re-check pub.dev pages after indexing finishes.

## Current Release Validation

- All 11 packages were uploaded to pub.dev as `0.1.0-dev.4`.
- Every package publish dry-run completed with 0 warnings.
- The release updates SDK callback hardening for QQ Android, QQ iOS, QQ
  HarmonyOS, and WeChat HarmonyOS.
- Root and package READMEs default to English and link to `README_CN.md`.
- `pubspec.yaml` includes `homepage`, monorepo package `repository`,
  `issue_tracker`, and `topics`.
- Android and iOS packages declare pub.dev-supported top-level `platforms`.
- HarmonyOS packages do not fake an unsupported pub.dev top-level `ohos`
  platform.

## Score Notes

Reasonable score items already handled:

- README / CHANGELOG / LICENSE.
- repository / homepage / issue tracker.
- package description length.
- public API dartdoc coverage.
- Android / iOS platform markers.

Items intentionally not forced:

- Do not fake Android / iOS / Web platforms for HarmonyOS packages.
- Do not fake Web / Windows / macOS / Linux support for wrapper packages.
- Do not copy full example projects into every federated implementation package.
- iOS Swift Package Manager support should be evaluated separately before adding
  `Package.swift`.

## SDK And License Notes

- `share_bridge_wechat_android` uses
  `com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0`.
- `share_bridge_wechat_ios` uses `WechatOpenSDK-XCFramework`.
- `share_bridge_wechat_ohos` uses `@tencent/wechat_open_sdk`.
- `share_bridge_qq_android` bundles
  `android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`.
- `share_bridge_qq_ios` bundles
  `ios/Frameworks/TencentOpenAPI.xcframework`.
- `share_bridge_qq_ohos` uses `@tencent/qq-open-sdk`.

If QQ SDK redistribution terms change later, switch to a host-provided SDK
integration model.

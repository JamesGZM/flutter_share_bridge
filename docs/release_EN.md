# Release Checklist

English | [中文](release.md)

The current development phase intentionally uses local `path` dependencies to keep monorepo integration simple.

## Current Dry-Run Results

Verified:

- `share_bridge_core`: `fvm dart pub publish --dry-run` passes with 0 warnings.
- `share_bridge_widgets`: dry-run is blocked by the local `path` dependency on `share_bridge_core`.
- `share_bridge_wechat`: dry-run is blocked by the local `path` dependency on `share_bridge_core`.
- `share_bridge_qq`: dry-run is blocked by the local `path` dependency on `share_bridge_core`.

This is expected for local development. Do not switch to hosted dependencies until the release preparation step.

## Release Order

Before publishing:

- Publish `share_bridge_core` first.
- Remove `publish_to: none` from each package `pubspec.yaml`.
- Replace local `path` dependencies with hosted version constraints, for example:

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.1
```

- Publish `share_bridge_widgets`.
- Publish `share_bridge_wechat`.
- Publish `share_bridge_qq`.
- Federated platform packages should be published in this order: `*_platform_interface`, `*_android`, `*_ios`, then the wrapper package.

## Commands Before Publishing

`share_bridge_core`:

```sh
cd packages/share_bridge_core
fvm dart analyze
fvm dart test
fvm dart pub publish --dry-run
```

Flutter packages:

```sh
cd packages/share_bridge_widgets
fvm flutter analyze
fvm flutter test
fvm flutter pub publish --dry-run

cd packages/share_bridge_wechat
fvm flutter analyze
fvm flutter test
fvm flutter pub publish --dry-run

cd packages/share_bridge_qq
fvm flutter analyze
fvm flutter test
fvm flutter pub publish --dry-run
```

Native plugin examples:

```sh
cd packages/share_bridge_wechat/example
fvm flutter build apk --debug
fvm flutter build ios --debug --no-codesign

cd packages/share_bridge_qq/example
fvm flutter build apk --debug
fvm flutter build ios --debug --no-codesign
```

## SDK And License Checks

- `share_bridge_wechat` Android uses `com.tencent.mm.opensdk:wechat-sdk-android-without-mta:6.8.0`.
- `share_bridge_wechat` iOS uses `WechatOpenSDK-XCFramework`, `2.0.5`.
- `share_bridge_qq_android` embeds `android/libs/open_sdk_3.5.19_r9483ffc7_lite.jar`.
- `share_bridge_qq_ios` embeds `ios/Frameworks/TencentOpenAPI.xcframework`.
- Before publishing `share_bridge_qq`, confirm that the QQ SDK license allows redistribution in a pub package. If it does not, switch to a user-supplied local SDK setup.

## Other Checks

- Run tests, analysis, and `pub publish --dry-run` for every package in order.
- Check whether the package names are available on pub.dev.
- Record Flutter, Dart, Android Gradle Plugin, Kotlin, Xcode, WeChat SDK, and QQ SDK versions.
- Confirm every README matches the implemented capability set.
- Confirm the privacy notice matches official SDK requirements.

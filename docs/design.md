# Architecture Design

English | [中文](design_CN.md)

This document records the current architecture boundaries for Flutter Share Bridge.

## Goals

Flutter Share Bridge is a share-only federated Flutter plugin set.

It is designed to:

- Share content to WeChat, QQ, and QZone.
- Let host apps depend only on the sharing providers they need.
- Keep UI optional and separate from platform SDK integration.
- Keep Dart content models independent from platform-specific SDK payloads.
- Support Android, iOS, and HarmonyOS through separate platform implementation packages.

It explicitly does not provide login, payment, OAuth, user profile APIs, analytics, telemetry, or backend services.

## Package Layout

```text
packages/
  share_bridge_core/
  share_bridge_widgets/
  share_bridge_platform_interface/
  share_bridge_wechat/
  share_bridge_wechat_android/
  share_bridge_wechat_ios/
  share_bridge_wechat_ohos/
  share_bridge_qq/
  share_bridge_qq_android/
  share_bridge_qq_ios/
  share_bridge_qq_ohos/

example/
docs/
```

Host apps normally depend on wrapper packages:

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.3
  share_bridge_wechat: ^0.1.0-dev.3
  share_bridge_qq: ^0.1.0-dev.3
  share_bridge_widgets: ^0.1.0-dev.3
```

Platform implementation packages are pulled in by Flutter `default_package` endorsement.

## Layer Responsibilities

| Package | Responsibility |
| --- | --- |
| `share_bridge_core` | Pure Dart models, result types, provider contract, and `ShareManager` |
| `share_bridge_widgets` | Optional Flutter share UI built only on `share_bridge_core` |
| `share_bridge_platform_interface` | Shared platform interface base types and MethodChannel contracts |
| `share_bridge_wechat` | WeChat provider API and provider-level orchestration |
| `share_bridge_wechat_android` | WeChat Android SDK integration |
| `share_bridge_wechat_ios` | WeChat iOS SDK integration |
| `share_bridge_wechat_ohos` | WeChat HarmonyOS OpenSDK integration |
| `share_bridge_qq` | QQ provider API, QQ-only privacy and HarmonyOS signing flow |
| `share_bridge_qq_android` | QQ Android SDK integration |
| `share_bridge_qq_ios` | QQ iOS SDK integration |
| `share_bridge_qq_ohos` | QQ HarmonyOS SDK integration |

## Dependency Rules

Allowed dependency direction:

```text
share_bridge_widgets -> share_bridge_core

share_bridge_wechat -> share_bridge_core
share_bridge_wechat -> share_bridge_platform_interface
share_bridge_wechat -> endorsed platform packages

share_bridge_qq -> share_bridge_core
share_bridge_qq -> share_bridge_platform_interface
share_bridge_qq -> endorsed platform packages

platform implementation packages -> share_bridge_platform_interface
platform implementation packages -> share_bridge_core
```

Forbidden dependency direction:

```text
share_bridge_core -> any Flutter plugin package
share_bridge_widgets -> share_bridge_wechat
share_bridge_widgets -> share_bridge_qq
share_bridge_platform_interface -> share_bridge_wechat
share_bridge_platform_interface -> share_bridge_qq
share_bridge_wechat_* -> share_bridge_wechat
share_bridge_qq_* -> share_bridge_qq
share_bridge_wechat -> share_bridge_qq
share_bridge_qq -> share_bridge_wechat
```

Provider-specific abilities belong to the provider package, not the shared platform interface, unless multiple providers need the same contract.

## Core Model Boundary

`ShareContent` describes what the host app wants to share. It must not contain SDK transport payloads, signatures, platform callback data, or native request JSON.

Supported content models:

- `ShareContent.webpage`
- `ShareContent.image`

Host apps are responsible for converting network images, Flutter assets, authenticated media, and generated images into local file paths or bytes before calling the plugin.

## Provider Boundary

Each provider owns its own platform-specific behavior:

- `WechatShareProvider` owns WeChat registration and sharing orchestration.
- `QqShareProvider` owns QQ registration, QQ privacy consent, and QQ HarmonyOS signing.

`ShareManager` only routes by `ShareChannel`, checks installation, and returns normalized `ShareResult` values.

## Platform Interface Boundary

`share_bridge_platform_interface` contains only shared contracts needed by platform implementations:

- Platform instance registration.
- Common initialization, installation, support, and sharing calls.
- MethodChannel argument/result normalization.

It must not grow provider-specific feature interfaces just because one platform needs a special capability. QQ-only abilities stay in `share_bridge_qq`; WeChat-only abilities stay in `share_bridge_wechat`.

## QQ HarmonyOS Signing

QQ HarmonyOS sharing requires a backend-generated signature. This signature is SDK transport data, not share content.

The callback is therefore exposed only by `QqShareProvider`:

```dart
QqShareProvider(
  appId: 'your_qq_app_id',
  qqHarmonySigner: (request) async {
    // Call your backend and return the signed payload.
  },
)
```

Behavior:

- Android and iOS ignore `qqHarmonySigner`.
- HarmonyOS calls `qqHarmonySigner` only when the active QQ platform implementation requires signed sharing.
- If `qqHarmonySigner` is missing on HarmonyOS, QQ sharing returns `unsupportedContent` with a clear message.
- Ordinary exceptions from the signer are mapped to `nativeError`; `ShareBridgeException` keeps its original code and message.

## HarmonyOS Design

HarmonyOS support uses independent endorsed federated packages:

- `share_bridge_wechat_ohos`
- `share_bridge_qq_ohos`

The wrapper packages declare `platforms.ohos.default_package`, so host apps still depend on `share_bridge_wechat` and `share_bridge_qq`.

HarmonyOS-specific SDK setup remains in the `ohos` implementation packages. Host configuration is documented in [HarmonyOS Integration](harmonyos_setup.md).

## Result Mapping

All platforms map native SDK results into `ShareResult`:

| Code | Meaning |
| --- | --- |
| `success` | Share completed successfully |
| `cancelled` | User cancelled |
| `appNotInstalled` | Target app is not installed |
| `unsupportedChannel` | No provider supports the target channel |
| `unsupportedContent` | The provider or platform cannot share this content |
| `invalidArgument` | Request arguments are invalid |
| `configError` | Host app configuration is invalid or incomplete |
| `permissionDenied` | Privacy consent or required permission is missing |
| `nativeError` | Native SDK returned an error |
| `busy` | Another share request is pending |

User cancellation must never be reported as a generic failure.

## Documentation Requirements

Repository documentation follows [AGENTS.md](../AGENTS.md):

- Default `README.md` and `docs/*.md` are English.
- Chinese files use `_CN.md`.
- Every public doc has a language switch near the top.
- Package README files must stay valid on pub.dev.
- Repository-level docs may include deeper setup and design details.

## Release Requirements

Before publishing a package:

- Run the fastest relevant `analyze` and `test` checks.
- Run `dart pub publish --dry-run` or `flutter pub publish --dry-run`.
- Verify pubspec metadata includes `homepage`, `repository`, `issue_tracker`, and `topics`.
- Verify `README.md` and `CHANGELOG.md` are mostly ASCII for pub.dev scoring.
- Update both English and Chinese docs when public behavior changes.

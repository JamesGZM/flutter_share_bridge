# Flutter Share Bridge

Modular, share-only Flutter packages for WeChat and QQ sharing.

This repository is in early development. The current milestone provides:

- `share_bridge_core`: pure Dart share models, provider contract, result codes, and manager.
- `share_bridge_widgets`: optional Flutter UI widgets that depend only on core.
- `share_bridge_wechat`: WeChat provider API and MethodChannel skeleton.
- `share_bridge_qq`: QQ/QZone provider API and MethodChannel skeleton.

Native WeChat and QQ SDK integrations are not complete yet.

## Packages

```text
packages/
  share_bridge_core/
  share_bridge_widgets/
  share_bridge_wechat/
  share_bridge_qq/
```

## Local Checks

```sh
cd packages/share_bridge_core && fvm dart test
cd packages/share_bridge_widgets && fvm flutter test
cd packages/share_bridge_wechat && fvm flutter test
cd packages/share_bridge_qq && fvm flutter test
```

Run `fvm flutter analyze` in each Flutter package before publishing.

## Design

See [design.md](design.md).

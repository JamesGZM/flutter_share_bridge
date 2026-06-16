# Flutter Share Bridge

模块化、分享-only 的 Flutter 分享插件集合，目标是按需接入微信、QQ 分享能力，并提供可选 UI。

当前处于早期开发阶段，已完成：

- `share_bridge_core`：纯 Dart 核心模型、Provider 协议、结果类型和 `ShareManager`。
- `share_bridge_widgets`：只依赖 core 的可选分享 UI。
- `share_bridge_wechat`：微信 Android / iOS 分享插件，已接入官方 SDK。
- `share_bridge_qq`：QQ / QQ 空间 Android / iOS 分享插件，已接入本地官方 SDK。

当前仍处于本地调试阶段，package 间使用 `path` 依赖，暂未切换到 pub hosted 依赖。

## 仓库结构

```text
packages/
  share_bridge_core/
  share_bridge_widgets/
  share_bridge_wechat/
  share_bridge_qq/
example/
```

`example/` 是聚合宿主示例，同时依赖 core、widgets、wechat、qq。各 package 下的 `example/` 只用于单插件调试。

## 本地检查

```sh
cd packages/share_bridge_core && fvm dart analyze && fvm dart test
cd packages/share_bridge_widgets && fvm flutter analyze && fvm flutter test
cd packages/share_bridge_wechat && fvm flutter analyze && fvm flutter test
cd packages/share_bridge_qq && fvm flutter analyze && fvm flutter test
```

原生示例编译：

```sh
cd example && fvm flutter build apk --debug
cd example && fvm flutter build ios --debug --no-codesign
cd packages/share_bridge_wechat/example && fvm flutter build apk --debug
cd packages/share_bridge_wechat/example && fvm flutter build ios --debug --no-codesign
cd packages/share_bridge_qq/example && fvm flutter build apk --debug
cd packages/share_bridge_qq/example && fvm flutter build ios --debug --no-codesign
```

发布前需要分别在每个 package 下运行分析、测试和 dry-run。除 `share_bridge_core` 外，其他包在本地调试阶段会因为 `share_bridge_core` 使用 `path` 依赖而无法通过 pub dry-run；发布时按 `docs/release.md` 切换依赖。

## 设计文档

见 [design.md](design.md)。

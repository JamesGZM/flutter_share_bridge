# Flutter Share Bridge

模块化、分享-only 的 Flutter 分享插件集合，目标是按需接入微信、QQ 分享能力，并提供可选 UI。

当前处于早期开发阶段，已完成：

- `share_bridge_core`：纯 Dart 核心模型、Provider 协议、结果类型和 `ShareManager`。
- `share_bridge_widgets`：只依赖 core 的可选分享 UI。
- `share_bridge_wechat`：微信分享 Provider 的 Dart API 与 MethodChannel 骨架。
- `share_bridge_qq`：QQ / QQ 空间分享 Provider 的 Dart API 与 MethodChannel 骨架。

微信、QQ 原生 SDK 的正式接入还没有完成。

## 仓库结构

```text
packages/
  share_bridge_core/
  share_bridge_widgets/
  share_bridge_wechat/
  share_bridge_qq/
```

## 本地检查

```sh
cd packages/share_bridge_core && fvm dart test
cd packages/share_bridge_widgets && fvm flutter test
cd packages/share_bridge_wechat && fvm flutter test
cd packages/share_bridge_qq && fvm flutter test
```

发布前需要分别在每个 package 下运行分析、测试和 dry-run。

## 设计文档

见 [design.md](design.md)。

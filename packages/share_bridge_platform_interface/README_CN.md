# share_bridge_platform_interface

[English](README.md) | 中文

Share Bridge federated 插件共用的 Flutter 平台接口包。

本包主要供平台实现包使用，例如 `share_bridge_wechat_android`、`share_bridge_wechat_ios`、`share_bridge_qq_android` 以及对应 HarmonyOS 实现包。业务代码通常不需要直接依赖本包，应优先依赖 `share_bridge_wechat`、`share_bridge_qq` 或 `share_bridge_core`。

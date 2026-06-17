# HarmonyOS 接入说明

[English](harmonyos_setup_EN.md) | 中文

HarmonyOS 支持计划放在后续里程碑。

Dart API 应尽量保持与 Android、iOS Provider 一致。当前平台或内容类型不支持时，必须返回明确的 `ShareResultCode`，不能静默失败。

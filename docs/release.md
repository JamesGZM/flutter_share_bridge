# 发布检查清单

当前开发阶段优先使用本地 `path` 依赖，保证 monorepo 内联调简单直接。

发布前再做以下调整：

- 先发布 `share_bridge_core`。
- 从四个 package 的 `pubspec.yaml` 中移除 `publish_to: none`。
- 将 `share_bridge_widgets`、`share_bridge_wechat`、`share_bridge_qq` 中的 `share_bridge_core` 依赖从本地 `path` 改为 pub 版本约束。
- 按顺序运行每个包的测试、分析和 `pub publish --dry-run`。
- 在 pub.dev 检查包名是否可用。
- 记录 Flutter、Dart、Android Gradle Plugin、Kotlin、Xcode、微信 SDK、QQ SDK 版本。
- 确认每个 README 与实际已实现能力一致。
- 确认隐私说明与官方 SDK 要求一致。

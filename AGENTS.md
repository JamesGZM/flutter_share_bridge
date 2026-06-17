# AGENTS.md

本文件是 Flutter Share Bridge 仓库的 agent 工作规范。后续维护、开发、重构、发布前检查，都优先以本文件为入口。

## 设计文档入口

- 开发或调整架构前，先阅读 [docs/design_CN.md](docs/design_CN.md)。
- 英文设计文档位于 [docs/design.md](docs/design.md)，用于对外同步和双语维护。
- 如果代码实现、包边界、平台能力、发布规则发生变化，需要同步更新设计文档。
- 如果本文件和设计文档冲突，以更具体、更贴近当前代码实现的一方为准，并在本次改动中修正另一份文档。

## 工作原则

- 优先做小而可 review 的 diff，除非明确要求，不做大范围重构。
- 编辑前先确认要改的文件，并用 3-6 条说明计划。
- 不臆造 API、配置、路径或平台能力；不确定时先搜索仓库。
- 保持现有代码风格、包结构和架构边界。
- 工作语言默认使用中文。

## 架构边界

- `share_bridge_core` 只放纯 Dart 模型、结果类型、provider 协议和 `ShareManager`。
- `share_bridge_widgets` 只做可选 UI，不依赖微信或 QQ provider。
- `share_bridge_platform_interface` 只放平台实现共同需要的基础接口和 MethodChannel 合约。
- 微信独有能力放在 `share_bridge_wechat` 或对应 `share_bridge_wechat_*` 平台包。
- QQ 独有能力放在 `share_bridge_qq` 或对应 `share_bridge_qq_*` 平台包。
- 不要把 QQ-only 或 WeChat-only 的能力接口放进 `share_bridge_platform_interface`，除非多个 provider 真实共享同一合约。
- `ShareContent` 只表达“要分享的内容”，不要塞平台 SDK payload、签名、回调数据或原生 JSON。

## HarmonyOS 约束

- HarmonyOS 平台能力通过独立 endorsed federated 子包实现。
- 宿主 App 依赖 `share_bridge_wechat` / `share_bridge_qq`，平台实现由 `default_package` 自动带入。
- QQ HarmonyOS 签名只通过 `QqShareProvider.qqHarmonySigner` 接入。
- 微信 HarmonyOS 不走 QQ 的 signer 设计。
- HarmonyOS 配置变化时，同步更新 `docs/harmonyos_setup_CN.md` 和 `docs/harmonyos_setup.md`。

## 文档规范

- 对外默认文档使用英文。
- 中文文档使用 `_CN.md` 后缀。
- 不新增 `_EN.md` 文件。
- 根目录 `README.md` 是英文。
- 根目录 `README_CN.md` 是中文。
- `docs/*.md` 默认英文。
- `docs/*_CN.md` 是中文版本。
- 长期维护的设计文档放在 `docs/design.md` 和 `docs/design_CN.md`，不要放在仓库根目录。
- 对外行为、宿主配置、平台能力、发布说明变化时，要同步更新英文和中文文档。

## 安全与密钥

- 不要把 secrets、token、私钥、`.env` 内容、证书、keystore、账号信息写入代码、文档或日志。
- 需要密钥时，让维护者通过环境变量或本机配置提供。
- 未经明确要求，不新增统计、埋点、遥测或额外网络请求。

## 代码质量

- 行为变化要补充或更新测试；如果当前包已有测试，优先沿用现有测试风格。
- 优先使用类型安全和明确错误处理。
- 注释只写在意图不明显的地方，不写重复代码含义的空注释。
- 平台错误要映射到统一 `ShareResult`，不要吞异常，也不要只返回 `false`。
- 用户取消必须映射为 `cancelled`，不要当作普通失败。

## 构建与检查

- 需要运行命令时，说明命令和目的。
- 可能影响构建时，先跑最快相关检查。
- Dart-only 包优先运行：

```sh
dart analyze
dart test
```

- Flutter 包优先运行：

```sh
flutter analyze
flutter test
```

- 发布相关改动需要对受影响 package 运行：

```sh
dart pub publish --dry-run
```

或：

```sh
flutter pub publish --dry-run
```

## 发布流程

- 发布前统一确认版本号，所有 `packages/*/pubspec.yaml` 的 `version` 需要一致。
- 所有内部依赖约束同步到本次版本，例如 `^0.1.0-dev.4`。
- 根 README、包 README、`docs/design*.md`、`docs/release*.md` 中的安装示例同步到新版本。
- 每个 package 的 `CHANGELOG.md` 必须先增加本次版本条目，且 `README.md` / `CHANGELOG.md` 尽量使用英文 ASCII，中文放到 `_CN.md`。
- 按依赖顺序发布：`share_bridge_core`、`share_bridge_platform_interface`、平台实现包、wrapper 包、`share_bridge_widgets`。
- 发布命令使用 `dart pub publish --force`，发布前必须先对同一 package 跑 `dart pub publish --dry-run`。
- 发布后更新 `docs/release.md` 和 `docs/release_CN.md` 的当前版本和验证结果。

## Git 与工作区

- 不要回滚用户已有改动，除非用户明确要求。
- 遇到无关 dirty files 时忽略，不要顺手整理。
- 不使用 `git reset --hard`、`git checkout --` 等破坏性命令，除非用户明确要求。
- 提交或发布前，先确认变更范围和版本号。

## 输出要求

- 代码改动完成后，说明改了什么、涉及哪些文件、跑了哪些检查。
- 调试问题时，说明假设、验证方式和最小修复。
- 回答保持简洁、具体、可执行。

# 架构设计

[English](design.md) | 中文

本文档记录 Flutter Share Bridge 当前的架构边界。

## 目标

Flutter Share Bridge 是一组只做分享的 federated Flutter 插件。

设计目标：

- 分享内容到微信、QQ、QQ 空间。
- 宿主 App 只依赖自己需要的分享 provider。
- UI 可选，并且和平台 SDK 接入分离。
- Dart 内容模型不承载平台 SDK 私有 payload。
- 通过独立平台实现包支持 Android、iOS、HarmonyOS。

明确不做登录、支付、OAuth、用户资料、统计、埋点或后台服务。

## 包结构

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

宿主 App 通常依赖主包：

```yaml
dependencies:
  share_bridge_core: ^0.1.0-dev.3
  share_bridge_wechat: ^0.1.0-dev.3
  share_bridge_qq: ^0.1.0-dev.3
  share_bridge_widgets: ^0.1.0-dev.3
```

平台实现包通过 Flutter `default_package` endorsement 自动带入。

## 分层职责

| 包 | 职责 |
| --- | --- |
| `share_bridge_core` | 纯 Dart 模型、结果类型、provider 协议、`ShareManager` |
| `share_bridge_widgets` | 只基于 `share_bridge_core` 的可选 Flutter 分享 UI |
| `share_bridge_platform_interface` | 平台实现共享的基础接口和 MethodChannel 合约 |
| `share_bridge_wechat` | 微信 provider API 和 provider 层编排 |
| `share_bridge_wechat_android` | 微信 Android SDK 接入 |
| `share_bridge_wechat_ios` | 微信 iOS SDK 接入 |
| `share_bridge_wechat_ohos` | 微信 HarmonyOS OpenSDK 接入 |
| `share_bridge_qq` | QQ provider API、QQ 独有隐私授权、QQ HarmonyOS 签名流程 |
| `share_bridge_qq_android` | QQ Android SDK 接入 |
| `share_bridge_qq_ios` | QQ iOS SDK 接入 |
| `share_bridge_qq_ohos` | QQ HarmonyOS SDK 接入 |

## 依赖规则

允许的依赖方向：

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

禁止的依赖方向：

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

provider 独有能力应该留在对应 provider 包里。除非多个 provider 共用同一能力合约，否则不应该下沉到共享 platform interface。

## 核心模型边界

`ShareContent` 只表达宿主 App 想分享什么，不表达 SDK 传输 payload、签名、平台回调数据或原生请求 JSON。

当前支持内容：

- `ShareContent.webpage`
- `ShareContent.image`

网络图片、Flutter asset、鉴权媒体、动态生成图片等，都应由宿主 App 先转换成本地文件路径或 bytes，再传给插件。

## Provider 边界

每个 provider 管自己的平台差异：

- `WechatShareProvider` 负责微信注册和分享编排。
- `QqShareProvider` 负责 QQ 注册、QQ 隐私授权、QQ HarmonyOS 签名。

`ShareManager` 只按 `ShareChannel` 路由、检查安装状态，并返回统一的 `ShareResult`。

## Platform Interface 边界

`share_bridge_platform_interface` 只放平台实现共同需要的合约：

- 平台实例注册。
- 通用初始化、安装检测、能力判断、分享调用。
- MethodChannel 参数和结果归一。

不能因为某一个平台或某一个 provider 需要特殊能力，就把 provider 独有接口塞进共享 platform interface。QQ 独有能力放在 `share_bridge_qq`，微信独有能力放在 `share_bridge_wechat`。

## QQ HarmonyOS 签名

QQ HarmonyOS 分享需要业务后台生成签名。签名属于 SDK 传输数据，不属于分享内容。

因此 callback 只暴露在 `QqShareProvider`：

```dart
QqShareProvider(
  appId: 'your_qq_app_id',
  qqHarmonySigner: (request) async {
    // 调用业务后台并返回已签名 payload。
  },
)
```

行为：

- Android 和 iOS 忽略 `qqHarmonySigner`。
- HarmonyOS 仅在当前 QQ 平台实现需要签名分享时调用 `qqHarmonySigner`。
- HarmonyOS 未配置 `qqHarmonySigner` 时，QQ 分享返回 `unsupportedContent` 并给出明确 message。
- signer 抛普通异常时映射为 `nativeError`；抛 `ShareBridgeException` 时保留原始 code 和 message。

## HarmonyOS 设计

HarmonyOS 使用独立 endorsed federated 子包：

- `share_bridge_wechat_ohos`
- `share_bridge_qq_ohos`

主包声明 `platforms.ohos.default_package`，所以宿主 App 仍然只依赖 `share_bridge_wechat` 和 `share_bridge_qq`。

HarmonyOS SDK 接入细节放在 `ohos` 实现包中。宿主配置见 [HarmonyOS 接入说明](harmonyos_setup_CN.md)。

## 结果映射

所有平台都把原生 SDK 结果映射为 `ShareResult`：

| Code | 含义 |
| --- | --- |
| `success` | 分享成功 |
| `cancelled` | 用户取消 |
| `appNotInstalled` | 目标 App 未安装 |
| `unsupportedChannel` | 没有 provider 支持该渠道 |
| `unsupportedContent` | provider 或平台不支持该内容 |
| `invalidArgument` | 请求参数不合法 |
| `configError` | 宿主配置错误或缺失 |
| `permissionDenied` | 缺少隐私授权或必要权限 |
| `nativeError` | 原生 SDK 返回错误 |
| `busy` | 上一个分享请求仍在等待回调 |

用户取消不能被当成普通失败。

## 文档要求

仓库文档遵循 [AGENTS.md](../AGENTS.md)：

- 默认 `README.md` 和 `docs/*.md` 使用英文。
- 中文文件使用 `_CN.md`。
- 每份公开文档顶部都要有语言切换入口。
- package README 必须在 pub.dev 上可读。
- 仓库级 docs 可以承载更完整的接入、设计和规范说明。

## 发布要求

发布 package 前需要：

- 跑最快相关 `analyze` 和 `test`。
- 跑 `dart pub publish --dry-run` 或 `flutter pub publish --dry-run`。
- 确认 pubspec metadata 包含 `homepage`、`repository`、`issue_tracker`、`topics`。
- 确认 `README.md` 和 `CHANGELOG.md` 主要为 ASCII，避免 pub.dev 扣分。
- 对外行为变化时，同步更新英文和中文文档。

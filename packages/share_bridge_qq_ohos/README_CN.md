# share_bridge_qq_ohos

[English](README.md) | 中文

Share Bridge 的 QQ HarmonyOS 分享实现包。

普通宿主 App 不需要直接依赖本包；依赖 `share_bridge_qq` 后，HarmonyOS 平台会通过 endorsed federated plugin 机制自动引入。

QQ HarmonyOS 分享需要业务后台完成 `shareJson + timestamp + nonce` 的签名。本包只接收 `QqShareProvider.qqHarmonySigner` 返回的已签名数据并转发给 QQ HarmonyOS SDK，不在客户端保存或计算 AppKey。

## 宿主配置

HarmonyOS 工程仍需要完成：

- `module.json5` 声明 `https`、`qqopenapi` 查询 scheme。
- Ability `skills` 配置 `qqopenapi` 回调，`host` 填 QQ 互联 AppID，`pathRegex` 包含 `auth|share`。
- `EntryAbility.onCreate/onNewWant` 调用 `ShareBridgeQqPlugin.handleWant(want)` 转发 QQ 回调。
- `build-profile.json5` 开启 `strictMode.useNormalizedOHMUrl`。
- DevEco Studio 中配置本机调试签名；签名、证书、keystore、`local.properties` 不提交。

完整说明见仓库根目录 [HarmonyOS 接入说明](../../docs/harmonyos_setup_CN.md)。

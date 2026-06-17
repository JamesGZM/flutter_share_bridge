# share_bridge_wechat_ohos

`share_bridge_wechat` 的 HarmonyOS 平台实现包。

通常无需直接依赖本包；业务侧依赖 `share_bridge_wechat` 即可通过 endorsed federated plugin 自动接入。

## 能力

- 微信好友网页分享
- 微信朋友圈网页分享
- 微信好友图片分享
- 微信朋友圈图片分享

HarmonyOS 微信分享不需要 `qqHarmonySigner` 这类签名回调，继续使用 `ShareContent.webpage` / `ShareContent.image`。

## 宿主配置

宿主 App 通常依赖 `share_bridge_wechat`，不直接依赖本包。

HarmonyOS 工程仍需要完成：

- `module.json5` 声明 `weixin`、`wxopensdk` 查询 scheme。
- `EntryAbility.onCreate/onNewWant` 调用 `ShareBridgeWechatPlugin.handleWant(want)`，用于接收微信分享成功、取消或错误回调。
- DevEco Studio 中配置本机调试签名；签名、证书、keystore、`local.properties` 不提交。

完整说明见仓库根目录 [HarmonyOS 接入说明](../../docs/harmonyos_setup.md)。

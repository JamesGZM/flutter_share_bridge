# share_bridge_qq_ohos

[English](README_EN.md) | 中文

Share Bridge 的 QQ HarmonyOS 分享实现包。

普通宿主 App 不需要直接依赖本包；依赖 `share_bridge_qq` 后，HarmonyOS 平台会通过 endorsed federated plugin 机制自动引入。

QQ HarmonyOS 分享需要业务后台完成 `shareJson + timestamp + nonce` 的签名。本包只接收 `QqShareProvider.qqHarmonySigner` 返回的已签名数据并转发给 QQ HarmonyOS SDK，不在客户端保存或计算 AppKey。

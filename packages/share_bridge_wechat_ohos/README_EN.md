# share_bridge_wechat_ohos

HarmonyOS implementation package for `share_bridge_wechat`.

Applications usually do not depend on this package directly. Depend on `share_bridge_wechat`; Flutter will load this endorsed platform package for HarmonyOS.

## Capabilities

- WeChat session webpage sharing
- WeChat timeline webpage sharing
- WeChat session image sharing
- WeChat timeline image sharing

WeChat HarmonyOS sharing does not require a signing callback like `qqHarmonySigner`; it continues to use `ShareContent.webpage` / `ShareContent.image`.

## Host Setup

Host apps normally depend on `share_bridge_wechat`, not this package directly.

The HarmonyOS project still needs:

- `module.json5` query schemes for `weixin` and `wxopensdk`.
- `EntryAbility.onCreate/onNewWant` forwarding to `ShareBridgeWechatPlugin.handleWant(want)` so WeChat success, cancel, and error callbacks can be received.
- A local debug signing config generated in DevEco Studio. Certificates, keystores, and `local.properties` are not committed.

See the repository-level [HarmonyOS setup guide](../../docs/harmonyos_setup_EN.md).

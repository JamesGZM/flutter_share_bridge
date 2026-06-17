# share_bridge_wechat_ohos

[![Pub Package](https://img.shields.io/pub/v/share_bridge_wechat_ohos.svg)](https://pub.dev/packages/share_bridge_wechat_ohos)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

HarmonyOS implementation package for `share_bridge_wechat`.

Applications usually do not depend on this package directly. Depend on `share_bridge_wechat`; Flutter will load this endorsed platform package for HarmonyOS.

## Capabilities

- WeChat session webpage sharing
- WeChat timeline webpage sharing
- WeChat session image sharing
- WeChat timeline image sharing

WeChat HarmonyOS sharing does not require a signing callback like `qqHarmonySigner`; it continues to use `ShareContent.webpage` and `ShareContent.image`.

## Host Setup

The HarmonyOS project still needs query schemes for `weixin` and `wxopensdk`, callback forwarding to `ShareBridgeWechatPlugin.handleWant(want)`, and a local debug signing config generated in DevEco Studio.

See the repository-level HarmonyOS setup guide for details.

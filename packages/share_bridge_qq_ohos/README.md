# share_bridge_qq_ohos

[![Pub Package](https://img.shields.io/pub/v/share_bridge_qq_ohos.svg)](https://pub.dev/packages/share_bridge_qq_ohos)
[![License](https://img.shields.io/github/license/JamesGZM/flutter_share_bridge)](https://github.com/JamesGZM/flutter_share_bridge/blob/master/LICENSE)

[Chinese](README_CN.md)

HarmonyOS implementation of QQ sharing for Share Bridge.

Applications usually do not depend on this package directly. Depend on `share_bridge_qq`; Flutter will load this endorsed platform package for HarmonyOS.

QQ HarmonyOS sharing requires the business backend to sign `shareJson + timestamp + nonce`. This package only forwards signed data returned by `QqShareProvider.qqHarmonySigner` to the QQ HarmonyOS SDK. It never stores or computes the AppKey on the client.

## Host Setup

The HarmonyOS project still needs query schemes for `https` and `qqopenapi`, a `qqopenapi` callback skill, `strictMode.useNormalizedOHMUrl`, forwarding from `EntryAbility.onCreate/onNewWant` to `ShareBridgeQqPlugin.handleWant(want)`, and a local debug signing config generated in DevEco Studio.

See the repository-level HarmonyOS setup guide for details.

# share_bridge_qq_ohos

English | [中文](README.md)

HarmonyOS implementation of QQ sharing for Share Bridge.

Host apps normally should not depend on this package directly. Depend on `share_bridge_qq`; this package is pulled in automatically on HarmonyOS through endorsed federated plugin registration.

QQ HarmonyOS sharing requires the business backend to sign `shareJson + timestamp + nonce`. This package only forwards signed data returned by `QqShareProvider.qqHarmonySigner` to the QQ HarmonyOS SDK. It never stores or computes the AppKey on the client.

## Host Setup

The HarmonyOS project still needs:

- `module.json5` query schemes for `https` and `qqopenapi`.
- Ability `skills` for the `qqopenapi` callback, with `host` set to the QQ Connect AppID and `pathRegex` including `auth|share`.
- `strictMode.useNormalizedOHMUrl` enabled in `build-profile.json5`.
- A local debug signing config generated in DevEco Studio. Certificates, keystores, and `local.properties` are not committed.

See the repository-level [HarmonyOS setup guide](../../docs/harmonyos_setup_EN.md).

# HarmonyOS Integration

English | [中文](harmonyos_setup.md)

QQ HarmonyOS sharing support has started. WeChat HarmonyOS is reserved for a later package using the same federated structure.

The Dart API should stay as consistent as possible with the Android and iOS providers. If the current platform or content type is unsupported, the implementation must return an explicit `ShareResultCode` instead of failing silently.

## QQ HarmonyOS

QQ HarmonyOS uses the standalone implementation package `share_bridge_qq_ohos`. Host apps normally depend on `share_bridge_qq`; the HarmonyOS implementation is pulled in by `default_package`.

### SDK Dependency

The HarmonyOS module depends on QQ Connect SDK in `oh-package.json5`:

```json5
"dependencies": {
  "@tencent/qq-open-sdk": ">=1.0.4"
}
```

Host apps still need to configure `module.json5` according to QQ Connect HarmonyOS documentation:

- `querySchemes`: `https`, `qqopenapi`
- Ability `skills` for the `qqopenapi` callback scheme
- `host` set to the QQ Connect AppID
- `pathRegex` including `auth|share`

The QQ SDK HAR is bytecode-compiled, so host projects also need to enable `useNormalizedOHMUrl` according to QQ Connect documentation.

### Signing Callback

QQ HarmonyOS sharing requires signing `shareJson + timestamp + nonce`. The AppKey must not be stored in the client, so the plugin does not compute signatures. Instead, it uses the optional `qqHarmonySigner` callback on `QqShareProvider`.

```dart
final provider = QqShareProvider(
  appId: 'your_qq_app_id',
  qqHarmonySigner: (request) async {
    final signed = await requestYourBackendToSign(
      type: request.type,
      shareJson: request.shareJson,
    );
    return QqHarmonyShareSignature(
      type: request.type,
      shareJson: request.shareJson,
      timestamp: signed.timestamp,
      nonce: signed.nonce,
      shareJsonSign: signed.shareJsonSign,
      openId: signed.openId,
    );
  },
);
```

`qqHarmonySigner` is used only by QQ HarmonyOS. Android and iOS ignore it and continue using their current native SDK flows.

Current capability mapping:

- `qq.friend` + webpage: ARK rich content, type `2`
- `qq.friend` + image: large image, type `2`
- `qq.qzone` + webpage: QZone sharing, type `3009`
- `qq.qzone` + image: currently returns `unsupportedContent`

## WeChat HarmonyOS

WeChat HarmonyOS will later use a separate `share_bridge_wechat_ohos` package. WeChat OpenSDK can construct `WXMediaMessage` and `SendMessageToWXReq` from normal `ShareContent.webpage/image`, so it does not need a QQ-style backend signing callback.

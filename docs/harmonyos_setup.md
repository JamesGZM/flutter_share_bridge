# HarmonyOS 接入说明

[English](harmonyos_setup_EN.md) | 中文

当前已开始接入 QQ HarmonyOS 分享；微信 HarmonyOS 按同样的 federated 子包结构预留，后续再实现。

Dart API 尽量保持与 Android、iOS Provider 一致。当前平台或内容类型不支持时，必须返回明确的 `ShareResultCode`，不能静默失败。

## QQ HarmonyOS

QQ HarmonyOS 使用独立实现包 `share_bridge_qq_ohos`。普通宿主 App 只需要依赖 `share_bridge_qq`，HarmonyOS 平台由 `default_package` 自动带入。

### SDK 依赖

插件的 HarmonyOS 模块通过 `oh-package.json5` 依赖 QQ 互联 SDK：

```json5
"dependencies": {
  "@tencent/qq-open-sdk": ">=1.0.4"
}
```

宿主工程仍需要按 QQ 互联 HarmonyOS 文档配置 `module.json5`，包括：

- `querySchemes`: `https`、`qqopenapi`
- Ability `skills` 中的 `qqopenapi` 回调 scheme
- `host` 填 QQ 互联 AppID
- `pathRegex` 包含 `auth|share`

QQ SDK 的 HAR 包采用字节码编译，宿主工程还需要按 QQ 互联文档开启 `useNormalizedOHMUrl`。

### 签名回调

QQ HarmonyOS 分享需要对 `shareJson + timestamp + nonce` 进行签名。AppKey 不能放在客户端，因此插件不计算签名，而是通过 `QqShareProvider` 的可选 `qqHarmonySigner` 交给业务后台完成。

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

`qqHarmonySigner` 只在 QQ HarmonyOS 实现中使用。Android / iOS 会忽略它，继续走现有原生 SDK 分享流程。

当前能力映射：

- `qq.friend` + 网页：ARK 图文分享，type `2`
- `qq.friend` + 图片：大图分享，type `2`
- `qq.qzone` + 网页：空间分享，type `3009`
- `qq.qzone` + 图片：暂返回 `unsupportedContent`

## 微信 HarmonyOS

微信 HarmonyOS 后续会新增 `share_bridge_wechat_ohos`。微信 OpenSDK 可从普通 `ShareContent.webpage/image` 构造 `WXMediaMessage` 和 `SendMessageToWXReq`，不需要 QQ HarmonyOS 这种后台签名 callback。

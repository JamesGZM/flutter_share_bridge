# Share Bridge 聚合示例

这个示例模拟真实宿主 App，同时依赖：

- `share_bridge_core`
- `share_bridge_widgets`
- `share_bridge_wechat`
- `share_bridge_qq`

示例使用 `ShareManager.isInstalled(ShareClient.wechat)` 和 `ShareManager.isInstalled(ShareClient.qq)` 检查客户端安装状态；实际分享仍直接传 `ShareChannel`。

## 本地运行

```sh
cd example
fvm flutter run \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

HarmonyOS 调试使用本机 OHOS Flutter：

```sh
direnv allow
cd example
fvm spawn custom_3.27.4_ohos_dev run -d <device-id> \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

如果不用 direnv，需要手动导出 DevEco Studio 的 `ohpm`、`hvigor`、`node` 和 `hdc` 路径；仓库根目录的 `.envrc` 是本机忽略文件，不提交。

首次运行前需要用 DevEco Studio 打开 `example/ohos`，在 `File -> Project Structure -> Signing Configs` 勾选 `Automatically generate signature` 生成本机调试签名。签名、证书、keystore 和 `local.properties` 都不提交。

## 宿主配置

`dart-define` 只传给 Dart 层，不会自动修改宿主平台配置。真机调试前还需要：

- Android：把 `AndroidManifest.xml` 里的 `tencentyour_qq_app_id` 替换成 `tencent` + QQ AppID。
- Android：确认微信 `WXEntryActivity` 包名与 `applicationId` 一致。
- iOS：把 `Info.plist` 里的 `your_wechat_app_id` 和 `tencentyour_qq_app_id` 替换为真实值。
- iOS：如启用 Universal Link，配置 Associated Domains 和开放平台后台。
- HarmonyOS：把 `example/ohos/entry/src/main/module.json5` 里的 `your_qq_app_id` 替换为 QQ 互联 AppID。
- HarmonyOS：微信回调已在 `EntryAbility.onCreate/onNewWant` 转发给 `ShareBridgeWechatPlugin.handleWant`，宿主 App 也需要保留同样逻辑。
- HarmonyOS：按微信 / QQ 开放平台配置鸿蒙应用包名、签名证书、AppID 和回调信息；本仓库不提交 keystore、证书或 `local.properties`。
- 开放平台：配置 Android 包名/签名、iOS Bundle ID、HarmonyOS 包名/证书、AppID、Universal Link。

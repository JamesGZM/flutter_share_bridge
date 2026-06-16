# Share Bridge 聚合示例

这个示例模拟真实宿主 App，同时依赖：

- `share_bridge_core`
- `share_bridge_widgets`
- `share_bridge_wechat`
- `share_bridge_qq`

## 本地运行

```sh
cd example
fvm flutter run \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

## 宿主配置

`dart-define` 只传给 Dart 层，不会自动修改宿主平台配置。真机调试前还需要：

- Android：把 `AndroidManifest.xml` 里的 `tencentyour_qq_app_id` 替换成 `tencent` + QQ AppID。
- Android：确认微信 `WXEntryActivity` 包名与 `applicationId` 一致。
- iOS：把 `Info.plist` 里的 `your_wechat_app_id` 和 `tencentyour_qq_app_id` 替换为真实值。
- iOS：如启用 Universal Link，配置 Associated Domains 和开放平台后台。
- 开放平台：配置 Android 包名/签名、iOS Bundle ID、AppID、Universal Link。

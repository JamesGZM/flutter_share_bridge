# share_bridge_wechat 示例

这个示例只演示微信分享插件的宿主接入。

## 本地运行

```sh
cd packages/share_bridge_wechat/example
fvm flutter run --dart-define=WECHAT_APP_ID=你的微信AppID
```

## 宿主配置

`dart-define` 只传给 Dart 层，不会自动修改 Android / iOS 宿主配置。真机调试前还需要：

- Android：确认 `android/app/src/main/kotlin/.../wxapi/WXEntryActivity.kt` 位于 `applicationId.wxapi` 包名下。
- Android：微信开放平台配置包名、签名和微信 AppID。
- iOS：把 `Info.plist` 中的 `your_wechat_app_id` 替换为真实微信 AppID。
- iOS：如启用 Universal Link，配置 Associated Domains、服务器 `apple-app-site-association` 和微信开放平台后台。

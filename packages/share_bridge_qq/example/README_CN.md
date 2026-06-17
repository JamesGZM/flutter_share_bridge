# share_bridge_qq 示例

这个示例只演示 QQ / QQ 空间分享插件的宿主接入。

## 本地运行

```sh
cd packages/share_bridge_qq/example
flutter run --dart-define=QQ_APP_ID=你的QQ互联AppID
```

## 宿主配置

`dart-define` 只传给 Dart 层，不会自动修改 Android / iOS 宿主配置。真机调试前还需要：

- Android：把 `AndroidManifest.xml` 中的 `tencentyour_qq_app_id` 替换为 `tencent` + QQ AppID。
- Android：QQ 互联开放平台配置包名、签名和 QQ AppID。
- Android：如果测试本地图片分享，确认 FileProvider authorities 是 `${applicationId}.fileprovider`。
- iOS：把 `Info.plist` 中的 `tencentyour_qq_app_id` 替换为 `tencent` + QQ AppID。
- iOS：如启用 Universal Link，配置 Associated Domains、服务器 `apple-app-site-association` 和 QQ 互联开放平台后台。

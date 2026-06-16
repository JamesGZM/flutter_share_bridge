# iOS 接入说明

## 微信分享

当前 iOS 侧已接入：

```ruby
pod 'WechatOpenSDK-XCFramework', '2.0.5'
```

插件支持：

- `wechat.session` 网页分享。
- `wechat.timeline` 网页分享。
- `wechat.session` 图片分享。
- `wechat.timeline` 图片分享。
- URL Scheme 回调。
- Universal Link 回调。

暂未处理：

- 小程序分享。
- 音乐、视频、文件分享。
- 更复杂的缩略图策略。

## 宿主 App 配置

### 1. 微信开放平台配置

需要在微信开放平台配置：

- Bundle ID。
- 微信 AppID。
- Universal Link。

Universal Link 必须和 Apple Associated Domains 以及服务器上的 `apple-app-site-association` 文件一致。

### 2. URL Scheme

宿主 App 的 `Info.plist` 需要添加 URL Scheme，通常为微信 AppID：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>weixin</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>你的微信AppID</string>
    </array>
  </dict>
</array>
```

### 3. LSApplicationQueriesSchemes

宿主 App 的 `Info.plist` 至少需要：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>weixin</string>
  <string>wechat</string>
  <string>weixinULAPI</string>
  <string>weixinURLParamsAPI</string>
</array>
```

### 4. Associated Domains

在 Xcode 的 Signing & Capabilities 中启用 Associated Domains，并添加：

```text
applinks:你的域名
```

服务器需要提供合法的 `apple-app-site-association` 文件。修改后建议删除 App 重新安装，避免 iOS 使用旧缓存。

### 5. AppDelegate / SceneDelegate 回调

插件会通过 FlutterPlugin 的 application delegate 接收 AppDelegate 回调。

如果宿主工程使用 SceneDelegate，还需要转发：

```swift
import share_bridge_wechat

override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  for context in URLContexts {
    if ShareBridgeWechatPlugin.handleOpen(context.url) {
      return
    }
  }
  super.scene(scene, openURLContexts: URLContexts)
}

override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
  if ShareBridgeWechatPlugin.handleOpenUniversalLink(userActivity) {
    return
  }
  super.scene(scene, continue: userActivity)
}
```

## 本地调试命令

示例工程支持通过 dart-define 传入微信 AppID：

```sh
cd packages/share_bridge_wechat/example
fvm flutter run --dart-define=WECHAT_APP_ID=你的微信AppID
```

注意：dart-define 只传给 Dart 层。iOS 的 URL Scheme、Associated Domains、Universal Link 仍需要在 Xcode 工程和微信开放平台中配置。

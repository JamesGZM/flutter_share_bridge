# iOS 接入说明

[English](ios_setup_EN.md) | 中文

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
import share_bridge_wechat_ios

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

原因：Flutter 插件依赖可以带入 SDK 和插件代码，但 URL Scheme、Associated Domains、Bundle ID、开放平台配置都属于宿主 App 配置，插件 example 只能提供模板。

## QQ 分享

当前 iOS 侧已接入你本地下载的 QQ 官方 Lite XCFramework：

```text
packages/share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework
```

QQ 互联官方 iOS SDK 包里的 module map 位于非标准目录，插件内已补充到每个 framework slice 的 `Modules/module.modulemap`，并改为标准 `framework module TencentOpenApi` 声明，确保 Swift 可以 `import TencentOpenApi`。

插件支持：

- `qq.friend` 网页分享。
- `qq.friend` 图片分享。
- `qq.qzone` 网页分享。
- URL Scheme 回调。
- Universal Link 回调。

暂未处理：

- QQ 空间纯图片分享。
- 登录、OAuth、用户资料。
- QQ 小程序、音乐、视频、文件等扩展类型。

### 1. QQ 互联配置

需要在 QQ 互联开放平台配置：

- Bundle ID。
- QQ AppID。
- Universal Link。

Universal Link 必须和 Apple Associated Domains 以及服务器上的 `apple-app-site-association` 文件一致。

### 2. URL Scheme

宿主 App 的 `Info.plist` 需要添加 URL Scheme，格式为 `tencent` + QQ AppID：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>qq</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>tencent你的QQAppID</string>
    </array>
  </dict>
</array>
```

例如 AppID 是 `222222`，则写 `tencent222222`。

### 3. LSApplicationQueriesSchemes

宿主 App 的 `Info.plist` 至少需要：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>mqqapi</string>
  <string>mqq</string>
  <string>mqqOpensdkSSoLogin</string>
  <string>mqqopensdkapiV2</string>
  <string>mqqopensdkapiV3</string>
  <string>wtloginmqq2</string>
  <string>mqqwpa</string>
  <string>mqzone</string>
  <string>mqqopensdkfriend</string>
  <string>mqqopensdkdataline</string>
  <string>mqqgamebindinggroup</string>
  <string>mqqopensdkgrouptribeshare</string>
  <string>tencentapi.qq.reqContent</string>
  <string>tencentapi.qzone.reqContent</string>
</array>
```

### 4. Associated Domains

如启用 Universal Link，在 Xcode 的 Signing & Capabilities 中启用 Associated Domains，并添加：

```text
applinks:你的域名
```

服务器需要提供合法的 `apple-app-site-association` 文件。修改后建议删除 App 重新安装，避免 iOS 使用旧缓存。

### 5. AppDelegate / SceneDelegate 回调

插件会通过 FlutterPlugin 的 application delegate 接收 AppDelegate 回调。

如果宿主工程使用 SceneDelegate，还需要转发：

```swift
import share_bridge_qq_ios

override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  for context in URLContexts {
    if ShareBridgeQqPlugin.handleOpen(context.url) {
      return
    }
  }
  super.scene(scene, openURLContexts: URLContexts)
}

override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
  if ShareBridgeQqPlugin.handleOpenUniversalLink(userActivity) {
    return
  }
  super.scene(scene, continue: userActivity)
}
```

## QQ 本地调试命令

示例工程支持通过 dart-define 传入 QQ AppID：

```sh
cd packages/share_bridge_qq/example
fvm flutter run --dart-define=QQ_APP_ID=你的QQ互联AppID
```

注意：dart-define 只传给 Dart 层。iOS 的 URL Scheme、Associated Domains、Universal Link 仍需要在 Xcode 工程和 QQ 互联开放平台中配置。示例工程的 `tencentyour_qq_app_id` 是占位值，真机调试前必须替换。

## 聚合示例

仓库根目录的 `example/` 是真实宿主视角的聚合示例，同时依赖：

- `share_bridge_core`
- `share_bridge_widgets`
- `share_bridge_wechat`
- `share_bridge_qq`

iOS 侧已经放入微信和 QQ 的 URL Scheme、`LSApplicationQueriesSchemes`、SceneDelegate 回调转发模板。真机调试前仍必须替换占位 AppID、配置 Associated Domains 和开放平台 Bundle ID。

```sh
cd example
fvm flutter run \
  --dart-define=WECHAT_APP_ID=你的微信AppID \
  --dart-define=QQ_APP_ID=你的QQ互联AppID
```

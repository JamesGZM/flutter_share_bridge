# iOS Integration

English | [中文](ios_setup.md)

## WeChat Sharing

The iOS implementation integrates:

```ruby
pod 'WechatOpenSDK-XCFramework', '2.0.5'
```

Supported:

- `wechat.session` webpage sharing.
- `wechat.timeline` webpage sharing.
- `wechat.session` image sharing.
- `wechat.timeline` image sharing.
- URL Scheme callbacks.
- Universal Link callbacks.

Not handled yet:

- Mini Program sharing.
- Music, video, file, and other extended content types.
- Advanced thumbnail strategies.

## Host App Configuration

### 1. WeChat Open Platform

Configure these values in the WeChat Open Platform:

- Bundle ID.
- WeChat AppID.
- Universal Link.

The Universal Link must match Apple Associated Domains and the `apple-app-site-association` file on your server.

### 2. URL Scheme

The host app `Info.plist` needs a URL Scheme, usually the WeChat AppID:

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
      <string>your_wechat_app_id</string>
    </array>
  </dict>
</array>
```

### 3. LSApplicationQueriesSchemes

The host app `Info.plist` needs at least:

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

Enable Associated Domains in Xcode Signing & Capabilities and add:

```text
applinks:your.domain
```

The server must provide a valid `apple-app-site-association` file. After changes, reinstall the app to avoid stale iOS cache.

### 5. AppDelegate / SceneDelegate Callbacks

The plugin receives AppDelegate callbacks through FlutterPlugin application delegate hooks.

If the host app uses SceneDelegate, forward callbacks:

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

## Local Debugging

The example supports passing the WeChat AppID with `dart-define`:

```sh
cd packages/share_bridge_wechat/example
flutter run --dart-define=WECHAT_APP_ID=your_wechat_app_id
```

`dart-define` is only passed to Dart. iOS URL Scheme, Associated Domains, Universal Link, and Open Platform settings must still be configured in Xcode and the WeChat Open Platform.

## QQ Sharing

The iOS implementation integrates the official QQ Lite XCFramework downloaded locally:

```text
packages/share_bridge_qq_ios/ios/Frameworks/TencentOpenAPI.xcframework
```

The module map in the official QQ Connect iOS SDK package is located in a non-standard directory. This plugin adds `Modules/module.modulemap` to every framework slice and uses a standard `framework module TencentOpenApi` declaration so Swift can `import TencentOpenApi`.

Supported:

- `qq.friend` webpage sharing.
- `qq.friend` image sharing.
- `qq.qzone` webpage sharing.
- URL Scheme callbacks.
- Universal Link callbacks.

Not handled yet:

- Pure image sharing to QZone.
- Login, OAuth, and user profile APIs.
- QQ Mini Program, music, video, file, and other extended content types.

### 1. QQ Connect Configuration

Configure these values in QQ Connect:

- Bundle ID.
- QQ AppID.
- Universal Link.

The Universal Link must match Apple Associated Domains and the `apple-app-site-association` file on your server.

### 2. URL Scheme

The host app `Info.plist` needs a URL Scheme in the format `tencent` + QQ AppID:

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
      <string>tencentyour_qq_app_id</string>
    </array>
  </dict>
</array>
```

For example, AppID `222222` becomes `tencent222222`.

### 3. LSApplicationQueriesSchemes

The host app `Info.plist` needs at least:

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

If Universal Link is enabled, enable Associated Domains in Xcode Signing & Capabilities and add:

```text
applinks:your.domain
```

The server must provide a valid `apple-app-site-association` file. After changes, reinstall the app to avoid stale iOS cache.

### 5. AppDelegate / SceneDelegate Callbacks

The plugin receives AppDelegate callbacks through FlutterPlugin application delegate hooks.

If the host app uses SceneDelegate, forward callbacks:

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

## QQ Local Debugging

The example supports passing the QQ AppID with `dart-define`:

```sh
cd packages/share_bridge_qq/example
flutter run --dart-define=QQ_APP_ID=your_qq_app_id
```

`dart-define` is only passed to Dart. iOS URL Scheme, Associated Domains, Universal Link, and QQ Connect settings must still be configured in Xcode and QQ Connect. The example's `tencentyour_qq_app_id` is a placeholder and must be replaced before real-device debugging.

## Aggregated Example

The root `example/` is an app-level integration example that depends on:

- `share_bridge_core`
- `share_bridge_widgets`
- `share_bridge_wechat`
- `share_bridge_qq`

The iOS side includes URL Scheme placeholders, `LSApplicationQueriesSchemes`, and SceneDelegate forwarding templates for WeChat and QQ. Before real-device debugging, replace placeholder AppIDs and configure Associated Domains and Open Platform Bundle IDs.

```sh
cd example
flutter run \
  --dart-define=WECHAT_APP_ID=your_wechat_app_id \
  --dart-define=QQ_APP_ID=your_qq_app_id
```

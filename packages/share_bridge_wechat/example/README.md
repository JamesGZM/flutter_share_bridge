# share_bridge_wechat example

Example app for the WeChat sharing package.

## Run

```sh
flutter run --dart-define=WECHAT_APP_ID=your_wechat_app_id
```

## Host Setup

`dart-define` only passes values to Dart code. It does not modify Android or iOS host configuration. Before real-device debugging, configure WeChat Open Platform package names, signatures, URL schemes, callback forwarding, and Universal Links when needed.

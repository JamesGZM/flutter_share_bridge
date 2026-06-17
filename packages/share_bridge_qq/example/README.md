# share_bridge_qq example

Example app for the QQ and QZone sharing package.

## Run

```sh
flutter run --dart-define=QQ_APP_ID=your_qq_app_id
```

## Host Setup

`dart-define` only passes values to Dart code. It does not modify Android or iOS host configuration. Before real-device debugging, configure QQ Connect package names, signatures, URL schemes, callback forwarding, FileProvider for local image sharing, and Universal Links when needed.

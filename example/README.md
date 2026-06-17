# Share Bridge Example

Example app for WeChat, QQ, QZone, and HarmonyOS sharing.

This example uses `ShareManager.isInstalled(ShareClient.wechat)` and `ShareManager.isInstalled(ShareClient.qq)` to check client installation. Real sharing still targets `ShareChannel` directly.

## Run

```sh
cd example
flutter run \
  --dart-define=WECHAT_APP_ID=your_wechat_app_id \
  --dart-define=QQ_APP_ID=your_qq_app_id
```

HarmonyOS local debugging uses the same Dart entry point:

```sh
cd example
flutter run -d <device-id> \
  --dart-define=WECHAT_APP_ID=your_wechat_app_id \
  --dart-define=QQ_APP_ID=your_qq_app_id
```

## Host Setup

`dart-define` only passes values to Dart code. It does not modify host platform configuration. Before real-device debugging, also complete the required Android, iOS, HarmonyOS, and developer-console settings.

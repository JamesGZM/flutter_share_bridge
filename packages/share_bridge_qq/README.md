# share_bridge_qq

QQ and QZone share-only provider for Share Bridge.

Current status: Dart API and MethodChannel skeleton are available. Native
Android/iOS QQ SDK integration is not complete yet.

## Usage Shape

```dart
await QqShareProvider.setPrivacyGranted(true);

final manager = ShareManager();
await manager.register(
  QqShareProvider(
    appId: 'your_qq_app_id',
    universalLink: 'https://example.com/qq/',
  ),
);
```

## Scope

- QQ/QZone sharing only.
- No login, OAuth, or user profile APIs.
- Android/iOS native SDK integration will be implemented in a later milestone.

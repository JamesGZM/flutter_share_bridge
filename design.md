# Share Bridge 模块化 Flutter 分享组件设计文档

文档版本：v0.1
项目阶段：开发前置设计
暂定包名前缀：`share_bridge_*`
目标平台：Android、iOS、HarmonyOS
目标能力：微信分享、QQ 分享、可选分享 UI 组件

---

## 0. 事实依据与参考范围

本文档的原生接入设计以官方 SDK 文档和成熟开源 Flutter 插件的公开实现经验为依据，不以猜测为准。

主要事实依据：

1. 微信开放平台移动应用文档：
   - Android 分享通过 `WXMediaMessage` 与 `SendMessageToWX.Req` 构造请求。
   - 微信好友、朋友圈、收藏通过 `SendMessageToWX.Req.scene` 区分，例如 `WXSceneSession`、`WXSceneTimeline`。
   - Android 回调入口依赖宿主包名下的 `wxapi/WXEntryActivity`，并通过 `IWXAPIEventHandler.onResp` 接收结果。
   - iOS 需要 `WXApi.registerApp(..., universalLink: ...)`、URL Scheme、Universal Link、`handleOpenURL` / `handleOpenUniversalLink` 回调转发。
   - 微信普通分享缩略图 `thumbData` 有大小限制，Android 文档示例说明普通消息缩略图不超过 32KB，小程序封面图限制不同，不能混用。
2. QQ 互联移动应用文档：
   - Android QQ 好友分享使用 `Tencent.shareToQQ(Activity, Bundle, IUiListener)`，不需要 QQ 登录授权，依赖手机 QQ 当前登录态。
   - Android QQ 空间分享使用 `shareToQzone` / QZone 相关参数，和 QQ 好友参数不是完全同一套能力。
   - QQ 纯图片分享有大小限制，官方文档示例指出纯图本地文件不应大于 5MB。
   - Android Q 以后分享本地图片要处理文件读权限；QQ 互联 SDK 3.3.8 与手 Q 8.2.8 起支持通过 `FileProvider` 方式分享文件。
   - iOS QQ 回调需要在 `openURL` / Universal Link 回调中转给 `QQApiInterface.handleOpenURL(..., delegate: ...)`，结果通过 `QQApiInterfaceDelegate.onResp` 返回。
3. Android 官方文档：
   - Android 11 以后存在包可见性限制；库如需查询或拉起目标 App，应在 AAR manifest 中声明 `<queries>`，或明确要求宿主 App 声明。
4. Apple 官方文档：
   - Universal Links 依赖 Associated Domains capability 与 `apple-app-site-association` 文件，iOS 9+ 支持。
5. Flutter 官方文档：
   - 原生 SDK 接入应通过 Platform Channels；MethodChannel 用于请求/响应，事件流或 native 主动回调用 EventChannel 或 MethodChannel 回调均可。
   - Federated plugins 是 Flutter 官方推荐的插件拆分方式之一，适合把平台接口、平台实现、面向用户 API 拆开。
6. 开源实现参考：
   - `OpenFlutter/fluwx`：微信 Flutter 插件，覆盖分享、支付、登录、小程序等能力；本文档只参考其微信 SDK 注册、iOS 配置、Android 回调接入经验，不继承其“大而全”能力边界。
   - `rxreader/tencent_kit`：QQ/Tencent Flutter 插件，覆盖 QQ 登录/分享及 HarmonyOS 部分能力；本文档只参考其 QQ 分享能力矩阵、隐私授权前置、Universal Link 配置经验。
   - `fluttercommunity/plus_plugins/share_plus`：系统分享插件，参考其返回结果抽象和平台分享限制说明；本项目不使用系统分享替代微信/QQ 官方 SDK 分享。

设计约束：

1. 官方 SDK 明确要求的配置，必须在 README 和 setup 文档中列为必填或条件必填。
2. 开源库只能作为工程经验参考，不能替代官方 SDK 文档。
3. 如果官方文档与开源实现冲突，以官方文档为准。
4. SDK 能力随版本变化，正式开发前要锁定并记录微信 SDK、QQ SDK、Flutter、Android Gradle Plugin、Kotlin、iOS deployment target 的最低版本。

---

## 1. 背景

当前 Flutter 项目需要支持微信、QQ 等平台分享能力，但现有第三方插件通常存在以下问题：

1. 能力较重，容易同时包含登录、支付、授权、用户资料等非分享能力。
2. 包粒度不够细，用户只需要微信分享时，可能仍然被迫引入其他平台能力。
3. UI 与分享能力耦合，用户想自定义分享弹窗时不够灵活。
4. 后续需要扩展 HarmonyOS，现有 Flutter 插件未必能完整覆盖。
5. 业务代码直接依赖某个第三方插件后，后续替换 SDK 或扩展平台成本较高。

因此，本项目希望实现一套模块化、分享-only、可扩展的 Flutter 分享组件生态。

---

## 2. 项目目标

本项目的核心目标是：

```text
只做分享，不做登录，不做支付，不做授权。
按需引入能力包。
UI 可选。
平台实现可扩展。
```

具体目标：

1. 提供基础核心库 `share_bridge_core`，定义分享模型、接口、注册机制、结果类型和错误类型。
2. 提供可选 UI 库 `share_bridge_widgets`，用于分享面板、分享按钮、分享宫格等组件。
3. 提供微信能力包 `share_bridge_wechat`，只接入微信分享能力。
4. 提供 QQ 能力包 `share_bridge_qq`，只接入 QQ 分享能力。
5. 支持 Android、iOS，后续扩展 HarmonyOS。
6. 用户只引入需要的平台包，避免无关 SDK 进入最终包。
7. Dart 层 API 保持稳定，Native 层可独立升级。
8. 业务层不直接依赖微信、QQ 原生 SDK，也不直接依赖现有第三方 Flutter 插件。

---

## 3. 非目标

本项目明确不做以下能力：

1. 不做微信支付。
2. 不做微信登录。
3. 不做 QQ 登录。
4. 不做获取用户资料。
5. 不做 OAuth 授权。
6. 不做后端 token 管理。
7. 不做广告、统计、埋点。
8. 不绕过官方 SDK 使用非标准 Scheme / Intent 强行分享。
9. 不把所有社交平台放进一个大包。
10. 不强制用户使用默认分享弹窗。

---

## 4. 包结构设计

推荐采用 Monorepo 管理多个 package：

```text
share_bridge/
  packages/
    share_bridge_core/
    share_bridge_widgets/
    share_bridge_wechat/
    share_bridge_qq/

  examples/
    basic_example/
    custom_ui_example/
    widgets_example/

  docs/
    design.md
    android_setup.md
    ios_setup.md
    harmonyos_setup.md
    privacy.md
    release.md
```

---

## 5. 包职责划分

### 5.1 share_bridge_core

核心基础库，只包含 Dart 侧抽象，不依赖 Flutter 原生平台 SDK，不依赖 UI。

职责：

1. 定义分享渠道。
2. 定义分享内容模型。
3. 定义分享结果。
4. 定义错误类型。
5. 定义分享 Provider 接口。
6. 提供分享管理器。
7. 负责 Provider 注册、查找、分发。
8. 负责基础参数校验。
9. 提供统一异常模型。

不包含：

1. 不包含 MethodChannel 实现。
2. 不包含微信 SDK。
3. 不包含 QQ SDK。
4. 不包含 UI 组件。
5. 不包含平台图标资源。

---

### 5.2 share_bridge_widgets

可选 UI 组件库，只依赖 `share_bridge_core`。

职责：

1. 提供默认分享弹窗。
2. 提供分享宫格组件。
3. 提供分享按钮组件。
4. 支持自定义渠道列表。
5. 支持自定义 icon、文案、布局、主题。
6. 调用 `ShareBridge` 或外部传入的 `ShareManager` 执行分享。

不包含：

1. 不依赖 `share_bridge_wechat`。
2. 不依赖 `share_bridge_qq`。
3. 不直接调用 Native SDK。
4. 不判断微信、QQ 的具体 SDK 逻辑。
5. 不内置强绑定官方品牌资源，默认图标应可替换。

---

### 5.3 share_bridge_wechat

微信分享能力包，只依赖 `share_bridge_core`。

职责：

1. 接入微信 Android SDK。
2. 接入微信 iOS SDK。
3. 后续接入微信 HarmonyOS SDK，若平台 SDK 暂未开放对应能力，则返回 unsupported。
4. 提供微信好友分享。
5. 提供微信朋友圈分享。
6. 支持网页分享。
7. 支持图片分享。
8. 后续支持小程序分享。
9. 处理微信 SDK 初始化、注册、回调、错误映射。

不包含：

1. 不做微信登录。
2. 不做微信支付。
3. 不做微信用户资料获取。
4. 不提供分享 UI。

---

### 5.4 share_bridge_qq

QQ 分享能力包，只依赖 `share_bridge_core`。

职责：

1. 接入 QQ Android SDK。
2. 接入 QQ iOS SDK。
3. 接入 QQ HarmonyOS SDK。
4. 提供 QQ 好友分享。
5. 提供 QQ 空间分享。
6. 支持网页分享。
7. 支持图片分享。
8. 处理 QQ SDK 初始化、注册、回调、错误映射。

不包含：

1. 不做 QQ 登录。
2. 不做 QQ 授权。
3. 不做用户资料获取。
4. 不提供分享 UI。

---

## 6. 依赖关系

正确依赖关系：

```text
share_bridge_widgets  ─┐
share_bridge_wechat   ─┼──> share_bridge_core
share_bridge_qq       ─┘
```

禁止依赖关系：

```text
share_bridge_core -> share_bridge_widgets
share_bridge_core -> share_bridge_wechat
share_bridge_core -> share_bridge_qq
share_bridge_widgets -> share_bridge_wechat
share_bridge_widgets -> share_bridge_qq
```

设计原则：

1. `core` 必须纯净。
2. `widgets` 只关心 UI，不关心具体平台 SDK。
3. `wechat` 和 `qq` 只关心各自平台能力。
4. 能力包之间不能互相依赖。
5. 用户未导入某个能力包时，对应 Native SDK 不应进入最终构建。

---

## 7. 推荐使用方式

### 7.1 只用微信分享，自定义 UI

```yaml
dependencies:
  share_bridge_core: ^0.1.0
  share_bridge_wechat: ^0.1.0
```

```dart
final shareManager = ShareManager();

await shareManager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/app/',
  ),
);

await shareManager.share(
  channel: ShareChannel.wechatSession,
  content: ShareContent.webpage(
    title: '今日水果上新',
    description: '点击查看新鲜水果',
    url: 'https://example.com/product/123',
    thumbPath: '/path/to/thumb.png',
  ),
);
```

---

### 7.2 微信 + QQ 分享，自定义 UI

```yaml
dependencies:
  share_bridge_core: ^0.1.0
  share_bridge_wechat: ^0.1.0
  share_bridge_qq: ^0.1.0
```

```dart
final shareManager = ShareManager();

await shareManager.register(
  WechatShareProvider(
    appId: 'your_wechat_app_id',
    universalLink: 'https://example.com/wechat/',
  ),
);

await shareManager.register(
  QqShareProvider(
    appId: 'your_qq_app_id',
    universalLink: 'https://example.com/qq/',
  ),
);
```

---

### 7.3 使用默认分享弹窗

```yaml
dependencies:
  share_bridge_core: ^0.1.0
  share_bridge_widgets: ^0.1.0
  share_bridge_wechat: ^0.1.0
  share_bridge_qq: ^0.1.0
```

```dart
await ShareBridgeSheet.show(
  context: context,
  manager: shareManager,
  content: ShareContent.webpage(
    title: '今日水果上新',
    description: '点击查看新鲜水果',
    url: 'https://example.com/product/123',
  ),
  channels: const [
    ShareChannel.wechatSession,
    ShareChannel.wechatTimeline,
    ShareChannel.qqFriend,
    ShareChannel.qzone,
  ],
);
```

---

## 8. Core API 设计

### 8.1 ShareChannel

为避免 enum 扩展困难，推荐使用值对象，而不是固定 enum。

```dart
class ShareChannel {
  final String id;

  const ShareChannel(this.id);

  static const wechatSession = ShareChannel('wechat.session');
  static const wechatTimeline = ShareChannel('wechat.timeline');
  static const qqFriend = ShareChannel('qq.friend');
  static const qzone = ShareChannel('qq.qzone');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShareChannel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
```

优势：

1. 后续可扩展微博、抖音、系统分享等渠道。
2. 第三方包可以定义自己的 channel。
3. 不需要每新增一个平台就修改 core enum。
4. 必须实现 `==` 和 `hashCode`，否则 `Set<ShareChannel>.contains()` 无法可靠识别第三方包创建的同 ID 渠道。

---

### 8.2 ShareContent

推荐使用抽象基类 + 工厂构造。

```dart
sealed class ShareContent {
  const ShareContent();

  const factory ShareContent.text({
    required String text,
  }) = ShareTextContent;

  const factory ShareContent.image({
    required String imagePath,
    String? thumbPath,
  }) = ShareImageContent;

  const factory ShareContent.webpage({
    required String title,
    required String description,
    required String url,
    String? thumbPath,
  }) = ShareWebPageContent;

  const factory ShareContent.miniProgram({
    required String title,
    required String description,
    required String webpageUrl,
    required String userName,
    required String path,
    String? thumbPath,
  }) = ShareMiniProgramContent;
}
```

MVP 阶段建议只实现：

```text
ShareWebPageContent
ShareImageContent
```

后续再补：

```text
ShareTextContent
ShareMiniProgramContent
```

---

### 8.3 ShareResult

```dart
class ShareResult {
  final ShareResultCode code;
  final String? message;
  final Object? raw;

  const ShareResult({
    required this.code,
    this.message,
    this.raw,
  });

  bool get isSuccess => code == ShareResultCode.success;
  bool get isCancelled => code == ShareResultCode.cancelled;
}
```

```dart
enum ShareResultCode {
  success,
  cancelled,
  failed,
  unsupportedChannel,
  unsupportedContent,
  appNotInstalled,
  sdkNotInitialized,
  invalidArgument,
  configError,
  permissionDenied,
  nativeError,
  timeout,
  busy,
  unknown,
}
```

---

### 8.4 ShareProvider

```dart
abstract interface class ShareProvider {
  String get providerId;

  Set<ShareChannel> get supportedChannels;

  bool get isInitialized;

  Future<void> initialize();

  Future<bool> isInstalled({
    ShareChannel? channel,
  });

  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  });

  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  });
}
```

设计要求：

1. 每个能力包实现自己的 Provider。
2. Provider 只负责自身平台。
3. Provider 不关心 UI。
4. Provider 内部处理 MethodChannel / Native 回调。
5. Provider 需要将 Native 错误统一转换为 `ShareResult`。
6. `initialize()` 不应在隐私协议授权前调用原生 SDK 的敏感初始化逻辑。
7. `isInstalled(channel: ...)` 支持按渠道判断可用性；当前微信可返回 provider 级别结果，QQ 可在未来区分 QQ / TIM / QZone 能力。

---

### 8.5 ShareManager

```dart
class ShareManager {
  final List<ShareProvider> _providers = [];

  Future<void> register(ShareProvider provider) async {
    _providers.add(provider);
  }

  Set<ShareChannel> get registeredChannels {
    return {
      for (final provider in _providers) ...provider.supportedChannels,
    };
  }

  Future<void> initializeAll() async {
    for (final provider in _providers) {
      if (!provider.isInitialized) {
        await provider.initialize();
      }
    }
  }

  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  }) async {
    final provider = _findProvider(channel);

    if (provider == null) {
      return const ShareResult(
        code: ShareResultCode.unsupportedChannel,
        message: 'No provider registered for this channel.',
      );
    }

    if (!provider.isInitialized) {
      await provider.initialize();
    }

    final supported = await provider.supports(
      channel: channel,
      content: content,
    );

    if (!supported) {
      return const ShareResult(
        code: ShareResultCode.unsupportedContent,
        message: 'This provider does not support the content.',
      );
    }

    return provider.share(
      channel: channel,
      content: content,
    );
  }

  ShareProvider? _findProvider(ShareChannel channel) {
    for (final provider in _providers) {
      if (provider.supportedChannels.contains(channel)) {
        return provider;
      }
    }
    return null;
  }
}
```

设计说明：

1. `register()` 只注册 Provider，不主动初始化原生 SDK，避免和隐私协议授权时机冲突。
2. 业务方可在用户同意隐私政策后主动调用 `initializeAll()`，也可以由 `share()` 在首次调用时延迟初始化。
3. `registeredChannels` 供 `share_bridge_widgets` 在未传 `channels` 时生成默认渠道列表。
4. MVP 阶段 `ShareManager` 不处理并发队列，Provider 内部维护单个 pending request；重复分享返回 `ShareResultCode.busy`。

---

## 9. Widgets API 设计

### 9.1 ShareBridgeSheet

```dart
class ShareBridgeSheet {
  static Future<ShareResult?> show({
    required BuildContext context,
    required ShareManager manager,
    required ShareContent content,
    List<ShareChannel>? channels,
    ShareBridgeSheetTheme? theme,
  });
}
```

行为：

1. 如果 `channels` 不传，则展示当前已注册 Provider 支持的渠道。
2. 如果渠道对应 App 未安装，可隐藏或置灰。
3. 用户点击渠道后，调用 `manager.share()`。
4. 分享成功、取消、失败后返回 `ShareResult`。
5. UI 层不直接捕获 Native SDK 细节。

---

### 9.2 ShareBridgeGrid

```dart
class ShareBridgeGrid extends StatelessWidget {
  final ShareManager manager;
  final ShareContent content;
  final List<ShareChannel> channels;
  final ValueChanged<ShareResult>? onResult;

  const ShareBridgeGrid({
    super.key,
    required this.manager,
    required this.content,
    required this.channels,
    this.onResult,
  });
}
```

适合用户嵌入自定义弹窗、底部面板、页面区域。

---

### 9.3 UI 自定义策略

`share_bridge_widgets` 需要支持：

1. 自定义渠道排序。
2. 自定义渠道标题。
3. 自定义渠道 icon。
4. 自定义按钮尺寸。
5. 自定义弹窗圆角、背景、间距。
6. 支持浅色 / 深色模式。
7. 支持隐藏未安装渠道。
8. 支持禁用不可用渠道。

不建议强行内置官方 Logo。默认可提供简单占位图标，真实品牌 icon 由使用方按平台规范自行提供。

---

## 10. 微信能力包设计

包名：

```text
share_bridge_wechat
```

### 10.1 支持渠道

```text
wechat.session
wechat.timeline
```

### 10.2 MVP 支持内容

```text
网页分享
图片分享
```

### 10.3 后续支持内容

```text
文本分享
小程序分享
音乐分享
视频分享
文件分享
```

小程序分享建议作为 v0.2 或 v0.3 能力，不放入首版 MVP。

---

### 10.4 Dart API

```dart
class WechatShareProvider implements ShareProvider {
  WechatShareProvider({
    required this.appId,
    this.universalLink,
  });

  final String appId;
  final String? universalLink;

  @override
  String get providerId => 'wechat';

  @override
  Set<ShareChannel> get supportedChannels => const {
        ShareChannel.wechatSession,
        ShareChannel.wechatTimeline,
      };

  @override
  bool get isInitialized;

  @override
  Future<void> initialize();

  @override
  Future<bool> isInstalled({
    ShareChannel? channel,
  });

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  });

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  });
}
```

---

### 10.5 Android 实现要点

需要处理：

1. 微信 SDK 依赖接入。
2. AppID 注册。
3. 分享请求构造。
4. 缩略图压缩。
5. Android 11+ 包可见性配置。
6. `WXEntryActivity` 回调。
7. `onResp` 结果映射。
8. R8 / ProGuard 规则。
9. 未安装微信时返回 `appNotInstalled`。
10. 参数不合法时返回 `invalidArgument`。

官方 SDK 映射：

1. 初始化：
   - 使用 `WXAPIFactory.createWXAPI(context, appId, true)` 获取 `IWXAPI`。
   - 使用 `api.registerApp(appId)` 注册到微信。
2. 安装与能力检测：
   - 使用 `api.isWXAppInstalled()` 判断微信是否安装。
   - 朋友圈需要额外确认当前微信版本支持对应 scene；不支持时返回 `unsupportedChannel`。
3. 网页分享：
   - `ShareWebPageContent.url` 映射到 `WXWebpageObject.webpageUrl`。
   - `title`、`description` 映射到 `WXMediaMessage.title`、`description`。
   - `thumbPath` 读取、压缩后写入 `WXMediaMessage.thumbData`，普通消息缩略图必须控制在微信 SDK 限制内。
4. 图片分享：
   - `ShareImageContent.imagePath` 映射到 `WXImageObject`。
   - 如果使用 bitmap，需要控制内存；如果使用路径或 byte array，需要按 SDK 当前版本文档确认可用构造方式。
5. 目标场景：
   - `ShareChannel.wechatSession` 映射 `SendMessageToWX.Req.WXSceneSession`。
   - `ShareChannel.wechatTimeline` 映射 `SendMessageToWX.Req.WXSceneTimeline`。
6. 回调：
   - 宿主 App 包名下必须存在 `wxapi/WXEntryActivity`。
   - `WXEntryActivity` 实现 `IWXAPIEventHandler`，在 `onResp(BaseResp resp)` 中把 `errCode`、`errStr`、`transaction` 转发给插件。
   - `SendMessageToWX.Req.transaction` 用作 requestId 承载字段，避免多个请求无法匹配。

Android 目录建议：

```text
share_bridge_wechat/
  android/
    src/main/kotlin/com/example/share_bridge_wechat/
      ShareBridgeWechatPlugin.kt
      WechatShareDelegate.kt
      WechatResultMapper.kt

    src/main/AndroidManifest.xml
```

---

### 10.6 iOS 实现要点

需要处理：

1. 微信 iOS SDK 接入。
2. AppID 注册。
3. URL Scheme 配置。
4. Universal Link 配置。
5. `openURL` 回调转发。
6. `continueUserActivity` 回调转发。
7. 分享结果映射。
8. 未安装微信检测。
9. Info.plist 配置说明。
10. 隐私合规说明。

iOS SDK 映射：

1. 初始化：
   - 使用 `WXApi.registerApp(appId, universalLink: universalLink)`。
   - `universalLink` 仅 iOS 使用，但 Dart API 可统一保留。
2. 配置：
   - `CFBundleURLTypes` 中 URL Scheme 通常为微信 AppID。
   - `LSApplicationQueriesSchemes` 至少需要覆盖微信 SDK 文档要求的 scheme。
   - Associated Domains 需要配置 `applinks:` 域名，并保证服务端存在合法 `apple-app-site-association`。
3. 回调：
   - URL Scheme 回调通过微信 SDK 文档中的 `handleOpenURL` / 当前版本等价 API 转发。
   - Universal Link 回调通过微信 SDK 文档中的 `handleOpenUniversalLink` / 当前版本等价 API 转发。
   - 需要同时说明 AppDelegate 与 SceneDelegate 两种宿主接入方式。
4. 结果映射：
   - `onResp` 中微信 SDK 成功码映射 `success`。
   - 用户取消映射 `cancelled`。
   - 普通错误映射 `nativeError`，配置类错误尽量映射 `configError`。

iOS 目录建议：

```text
share_bridge_wechat/
  ios/
    Classes/
      ShareBridgeWechatPlugin.swift
      WechatShareDelegate.swift
      WechatResultMapper.swift
```

---

### 10.7 HarmonyOS 实现要点

HarmonyOS 作为后续阶段支持。

设计要求：

1. Dart API 不变。
2. Provider 不变。
3. 仅补充 `ohos/` 平台实现。
4. 若官方 SDK 暂不支持某类分享，返回 `unsupportedContent`。
5. 若当前平台暂未实现，返回 `unsupportedChannel` 或 `nativeError`，不能静默失败。

目录预留：

```text
share_bridge_wechat/
  ohos/
    src/main/ets/
      ShareBridgeWechatPlugin.ets
      WechatShareDelegate.ets
```

---

## 11. QQ 能力包设计

包名：

```text
share_bridge_qq
```

### 11.1 支持渠道

```text
qq.friend
qq.qzone
```

### 11.2 MVP 支持内容

```text
网页分享
图片分享
```

说明：QQ 好友图片分享作为 MVP 明确支持；QQ 空间图片分享按官方 SDK 当前版本和真机验证结果决定，不能稳定支持的平台返回 `unsupportedContent`。

### 11.3 后续支持内容

```text
文本分享
音乐分享
视频分享
文件分享
```

---

### 11.4 Dart API

```dart
class QqShareProvider implements ShareProvider {
  QqShareProvider({
    required this.appId,
    this.universalLink,
  });

  final String appId;
  final String? universalLink;

  @override
  String get providerId => 'qq';

  @override
  Set<ShareChannel> get supportedChannels => const {
        ShareChannel.qqFriend,
        ShareChannel.qzone,
      };

  @override
  bool get isInitialized;

  @override
  Future<void> initialize();

  @override
  Future<bool> isInstalled({
    ShareChannel? channel,
  });

  @override
  Future<bool> supports({
    required ShareChannel channel,
    required ShareContent content,
  });

  @override
  Future<ShareResult> share({
    required ShareChannel channel,
    required ShareContent content,
  });
}
```

---

### 11.5 Android 实现要点

需要处理：

1. QQ SDK 依赖接入。
2. AppID 初始化。
3. 分享参数构造。
4. Activity 上下文获取。
5. 分享回调处理。
6. QQ / TIM 安装检测。
7. Android 包可见性配置。
8. R8 / ProGuard 规则。
9. 分享失败结果映射。
10. 用户取消结果映射。

官方 SDK 映射：

1. 初始化：
   - 使用 `Tencent.createInstance(appId, context)` 初始化。
   - 如果需要支持 Android Q/Android 11 以后本地图片文件分享，优先使用 `Tencent.createInstance(appId, context, authorities)`，其中 `authorities` 默认建议为 `${applicationId}.fileprovider`。
2. QQ 好友网页分享：
   - 使用 `Tencent.shareToQQ(Activity activity, Bundle params, IUiListener listener)`。
   - `ShareWebPageContent` 映射为 `QQShare.SHARE_TO_QQ_TYPE_DEFAULT`。
   - 标题、摘要、目标 URL、缩略图 URL/路径分别映射到 QQ SDK 对应 `Bundle` key。
3. QQ 好友图片分享：
   - 使用 `QQShare.SHARE_TO_QQ_TYPE_IMAGE`。
   - 本地纯图片文件要校验文件存在、可读、大小限制；官方示例中纯图本地文件超过 5MB 会回调错误。
4. QQ 空间分享：
   - 不要简单复用 `shareToQQ` 的所有参数。QZone 有独立接口和能力限制。
   - MVP 支持 QZone 网页分享；QZone 图片分享需要以官方 SDK 当前能力为准，若只支持图文/说说场景，应在 `supports()` 中按内容返回 `unsupportedContent`。
5. 回调：
   - `IUiListener.onComplete` 映射 `success`。
   - `IUiListener.onCancel` 映射 `cancelled`。
   - `IUiListener.onError` 映射 `nativeError` 或 `invalidArgument`。
   - 如果 SDK 返回版本不支持、参数错误等 message，需要在 mapper 中细分到 `unsupportedContent`、`unsupportedChannel`、`invalidArgument`。
6. Activity 结果：
   - 分享回调依赖 Activity 生命周期时，需要在 `onActivityResult` 中调用 QQ SDK 对应处理方法。
   - Flutter 插件必须实现 `ActivityAware`，并在 Activity detach / reattach 时清理或恢复 pending request。

Android 文件分享要求：

1. Android Q 以后，直接把外部存储路径传给 QQ 可能导致手 Q 无法读取。
2. 插件应优先把待分享图片复制到 App 可控缓存目录，再通过 `FileProvider` 授权给 QQ。
3. README 必须说明宿主 App 是否需要合并 `provider`、`file_paths.xml`、`queries`。
4. 如果用户传入的图片路径不可读，返回 `invalidArgument`。

Android 目录建议：

```text
share_bridge_qq/
  android/
    src/main/kotlin/com/example/share_bridge_qq/
      ShareBridgeQqPlugin.kt
      QqShareDelegate.kt
      QqResultMapper.kt

    src/main/AndroidManifest.xml
```

---

### 11.6 iOS 实现要点

需要处理：

1. QQ iOS SDK 接入。
2. AppID 注册。
3. URL Scheme 配置。
4. Universal Link 配置。
5. 回调转发。
6. 分享结果映射。
7. 未安装 QQ 检测。
8. Info.plist 配置说明。
9. 隐私合规说明。

iOS SDK 映射：

1. 初始化：
   - 使用 QQ 互联 iOS SDK 当前版本要求的 AppID 注册方式。
   - Universal Link 路径应和 QQ 互联后台配置一致。
2. 回调：
   - URL Scheme 回调中调用 `QQApiInterface.handleOpenURL(..., delegate: ...)`。
   - Universal Link 回调中调用 QQ SDK 当前版本要求的 Universal Link 处理 API。
   - 结果通过 `QQApiInterfaceDelegate.onResp(QQBaseResp *)` 接收。
3. 结果映射：
   - `QQBaseResp.resultCode` / `rthCode` 成功值映射 `success`。
   - 取消映射 `cancelled`。
   - `rthMsg` 仅作为调试 message，不能直接作为用户可见文案。
4. SceneDelegate：
   - 如果 SDK 当前版本不支持或接入复杂，README 必须明确 AppDelegate / SceneDelegate 兼容要求。

目录建议：

```text
share_bridge_qq/
  ios/
    Classes/
      ShareBridgeQqPlugin.swift
      QqShareDelegate.swift
      QqResultMapper.swift
```

---

### 11.7 HarmonyOS 实现要点

HarmonyOS 阶段建议优先做 QQ，因为 QQ 互联已经有 HarmonyOS SDK 接入路径。

设计要求：

1. `share_bridge_qq` 内部新增 `ohos/` 实现。
2. Dart 层不新增破坏性 API。
3. 与 Android/iOS 共用同一套 `ShareResult`。
4. 若 HarmonyOS 上某个内容类型暂不支持，返回 `unsupportedContent`。
5. 若 QQ 未安装，返回 `appNotInstalled`。

目录预留：

```text
share_bridge_qq/
  ohos/
    src/main/ets/
      ShareBridgeQqPlugin.ets
      QqShareDelegate.ets
```

---

## 12. MethodChannel 设计

每个能力包维护自己的 MethodChannel。

### 12.1 微信 Channel

```text
share_bridge_wechat
```

方法：

```text
initialize
isInstalled
supports
shareWebPage
shareImage
```

事件：

```text
onShareResult
```

---

### 12.2 QQ Channel

```text
share_bridge_qq
```

方法：

```text
initialize
isInstalled
supports
shareWebPage
shareImage
```

事件：

```text
onShareResult
```

---

### 12.3 请求 ID 机制

所有分享请求应生成 requestId。

```dart
class ShareRequest {
  final String requestId;
  final ShareChannel channel;
  final ShareContent content;
}
```

Native 回调时携带 requestId：

```json
{
  "requestId": "xxx",
  "code": "success",
  "message": null
}
```

这样可以避免多个异步分享请求之间的回调混乱。

MVP 阶段可以限制同一时间只允许一个分享请求：

```text
如果已有分享请求未完成，再次调用 share() 返回 busy。
```

实现要求：

1. Dart 层生成 `requestId`，并传给 Native。
2. 微信 Android 可把 `requestId` 写入 `SendMessageToWX.Req.transaction`。
3. QQ Android 的 `IUiListener` 与发起请求绑定，Native 层仍需保存当前 pending requestId。
4. iOS 回调如果 SDK 原始响应不携带 requestId，MVP 只允许一个 pending request，通过当前 pending requestId 匹配。
5. Native 回调到 Dart 建议使用 MethodChannel 反向调用 `onShareResult`；如果后续需要广播安装状态、SDK 日志或生命周期事件，再引入 EventChannel。

---

## 13. 分享能力矩阵

MVP 阶段：

| 渠道    | 网页分享 | 图片分享 | 文本分享 |   小程序分享 |
| ----- | ---: | ---: | ---: | ------: |
| 微信好友  |   支持 |   支持 |   暂缓 |      后续 |
| 微信朋友圈 |   支持 |   支持 |   暂缓 | 不作为 MVP |
| QQ 好友 |   支持 |   支持 |   暂缓 | 不作为 MVP |
| QQ 空间 |   支持 | 条件支持 |   暂缓 | 不作为 MVP |

说明：

1. 首版优先保证网页分享和图片分享。
2. 文本分享虽然实现简单，但不同平台限制不一致，建议放到第二阶段。
3. 小程序分享涉及参数、审核、平台限制，建议单独设计。
4. 文件、音乐、视频不纳入首版。
5. QQ 空间图片能力在 Android/iOS SDK 上存在不同对象和参数路径；MVP 只承诺官方 SDK 当前版本明确支持、真机验证通过的路径。若本地纯图片在目标平台不可稳定分享，`supports()` 必须返回 `unsupportedContent`，不能伪成功。

---

## 14. 错误码设计

统一错误码：

```text
success
cancelled
failed
unsupportedChannel
unsupportedContent
appNotInstalled
sdkNotInitialized
invalidArgument
configError
permissionDenied
nativeError
timeout
busy
unknown
```

错误处理原则：

1. 用户取消必须明确返回 `cancelled`，不能当成失败。
2. 未安装目标 App 返回 `appNotInstalled`。
3. 未注册 Provider 返回 `unsupportedChannel`。
4. 内容类型不支持返回 `unsupportedContent`。
5. 配置错误返回 `configError`。
6. Native SDK 异常返回 `nativeError`。
7. 不允许吞异常。
8. 不允许只返回 `false`，必须包含明确错误类型。

---

## 15. 配置设计

### 15.1 微信配置

```dart
WechatShareProvider(
  appId: 'wx_xxx',
  universalLink: 'https://example.com/wechat/',
)
```

Android 还需要文档说明：

```text
包名
签名
微信开放平台 AppID
AndroidManifest 配置
WXEntryActivity 配置
queries 配置
R8 / ProGuard 配置
```

iOS 还需要文档说明：

```text
URL Scheme
Universal Link
Associated Domains
Info.plist
AppDelegate / SceneDelegate 回调转发
LSApplicationQueriesSchemes
```

---

### 15.2 QQ 配置

```dart
QqShareProvider(
  appId: 'xxx',
  universalLink: 'https://example.com/qq/',
)
```

Android 还需要文档说明：

```text
QQ 互联 AppID
AndroidManifest 配置
Activity 回调
queries 配置
R8 / ProGuard 配置
```

iOS 还需要文档说明：

```text
URL Scheme
Universal Link
Info.plist
AppDelegate / SceneDelegate 回调转发
LSApplicationQueriesSchemes
```

---

## 16. 隐私与合规设计

由于底层会接入微信、QQ 官方 SDK，必须提供合规说明文档。

文档位置：

```text
docs/privacy.md
```

内容应包括：

1. 本库只封装分享能力。
2. 本库不主动采集用户个人信息。
3. 本库不做登录。
4. 本库不做支付。
5. 本库不保存 token。
6. 本库不上传用户数据到第三方服务器。
7. 目标 App 需要按照微信、QQ 官方 SDK 要求完善隐私政策。
8. App 应在用户同意隐私政策后再初始化相关 SDK。
9. 如果 App 使用图片分享，需要说明本地图片读取来源和权限。
10. 如果平台 SDK 要求声明设备信息、剪切板、应用安装检测等，接入方需要在隐私政策中声明。

API 层面可以提供：

```dart
await WechatShareProvider.setPrivacyGranted(true);
await QqShareProvider.setPrivacyGranted(true);
```

初始化策略：

1. `ShareManager.register()` 只保存 Provider，不调用原生 SDK 初始化。
2. Provider 的 `initialize()` 必须先检查隐私授权状态。
3. 用户未授权隐私协议时，`initialize()` 不调用微信/QQ SDK 注册接口。
4. 用户授权后，业务可主动调用 `shareManager.initializeAll()`。
5. 如果业务没有主动初始化，首次 `share()` 时允许 lazy initialize，但仍必须先检查隐私授权状态。

如果未授权隐私协议，调用分享可以返回：

```text
permissionDenied
```

---

## 17. 生命周期与回调设计

### 17.1 Android

需要处理：

1. 插件 attachedToEngine。
2. 插件 attachedToActivity。
3. Activity result 回调。
4. 微信 EntryActivity 回调。
5. Activity 重建。
6. FlutterEngine 多实例场景。
7. 应用从微信 / QQ 返回时的结果派发。

Android 回调路由原则：

1. 微信：
   - `WXEntryActivity` 是宿主 App 包名相关的固定入口，插件不能假设自己包名下的 Activity 会被微信回调。
   - 插件 README 必须要求宿主 App 添加或继承一个 `WXEntryActivity`，并把回调转发给插件提供的静态 dispatcher。
   - dispatcher 只保存弱引用或明确生命周期绑定，避免 Activity 泄漏。
2. QQ：
   - `shareToQQ` / `shareToQzone` 依赖当前 `Activity`，插件必须实现 `ActivityAware`。
   - 如果 Activity detached 时仍有 pending request，应返回 `nativeError` 或在 reattach 后继续等待，不能永久挂起。
   - `onActivityResult` 与 `IUiListener` 的调用顺序按 QQ SDK 当前文档和 demo 验证后固化。
3. 多 FlutterEngine：
   - MVP 不支持同一进程多个 FlutterEngine 同时发起分享。
   - Native dispatcher 只允许一个 active engine/pending request；冲突时返回 `busy`。
4. 冷启动：
   - 如果微信/QQ 回调导致 App 冷启动，Native 层可以先缓存最近一次回调。
   - Dart engine 完成注册后再派发；若没有 pending request，应作为 orphan callback 记录日志并忽略。

### 17.2 iOS

需要处理：

1. plugin registrar。
2. application openURL。
3. continueUserActivity。
4. SceneDelegate 场景。
5. 分享结果回调。
6. App 冷启动回调场景。

iOS 回调路由原则：

1. 插件必须提供 AppDelegate 接入说明。
2. 插件必须提供 SceneDelegate 接入说明；若某 SDK 版本存在限制，需要在 README 明确最低支持方式。
3. URL Scheme 与 Universal Link 都要转发给对应 SDK。
4. iOS MVP 同样只允许一个 pending request；回调不带 requestId 时使用当前 pending request 匹配。
5. 如果宿主没有转发回调，分享请求最终通过 timeout 返回 `timeout`，并在 debug 日志提示配置缺失。

### 17.3 HarmonyOS

需要处理：

1. Flutter HarmonyOS 插件注册方式。
2. Ability 生命周期。
3. SDK 回调。
4. 分享结果派发。
5. 未实现能力的降级返回。

---

## 18. Example 设计

至少提供三个示例。

### 18.1 basic_example

目标：

```text
展示不使用 widgets，仅使用 core + wechat / qq 完成分享。
```

包含：

1. 初始化 Provider。
2. 网页分享到微信好友。
3. 网页分享到朋友圈。
4. 网页分享到 QQ。
5. 网页分享到 QZone。
6. 图片分享。
7. 错误结果展示。

---

### 18.2 widgets_example

目标：

```text
展示默认分享弹窗。
```

包含：

1. 底部分享面板。
2. 渠道自动过滤。
3. 自定义渠道排序。
4. 自定义标题。
5. 分享结果 Toast。

---

### 18.3 custom_ui_example

目标：

```text
展示用户完全自定义 UI。
```

包含：

1. 自定义按钮。
2. 自定义弹窗。
3. 只接微信，不接 QQ。
4. 直接调用 `ShareManager.share()`。

---

## 19. 测试策略

### 19.1 单元测试

`share_bridge_core` 必须覆盖：

1. Provider 注册。
2. Provider 查找。
3. 未注册渠道。
4. 不支持内容类型。
5. 分享结果映射。
6. 参数校验。
7. 多 Provider 并存。

---

### 19.2 Widget 测试

`share_bridge_widgets` 覆盖：

1. 渠道列表渲染。
2. 自定义 icon。
3. 自定义标题。
4. 点击渠道触发分享。
5. 分享结果回调。
6. 未安装渠道隐藏 / 置灰逻辑。

---

### 19.3 集成测试

必须在真机测试：

1. Android 微信已安装。
2. Android 微信未安装。
3. Android QQ 已安装。
4. Android QQ 未安装。
5. iOS 微信已安装。
6. iOS 微信未安装。
7. iOS QQ 已安装。
8. iOS QQ 未安装。
9. 用户取消分享。
10. 分享成功。
11. 参数错误。
12. Universal Link 配置错误。
13. Android 签名错误。
14. HarmonyOS 真机测试。

模拟器测试只能作为辅助，不能作为最终验证依据。

---

## 20. 发布规范

### 20.1 包命名

暂定包名：

```text
share_bridge_core
share_bridge_widgets
share_bridge_wechat
share_bridge_qq
```

发布前必须检查：

1. pub.dev 是否已有同名包。
2. GitHub 是否有同名高热项目。
3. 是否与大型 SDK 或商标冲突。
4. 是否符合 Dart 包命名规范。
5. 是否方便未来扩展其他平台。

备选命名：

```text
share_adapter_core
share_adapter_widgets
share_adapter_wechat
share_adapter_qq
```

```text
share_port_core
share_port_widgets
share_port_wechat
share_port_qq
```

---

### 20.2 版本策略

建议所有包从 `0.1.0` 开始。

```text
0.1.x：MVP，API 允许小幅调整
0.2.x：增加小程序分享、文本分享
0.3.x：完善 HarmonyOS
1.0.0：API 稳定，正式发布
```

破坏性变更必须提升 minor 或 major，并写清 migration guide。

### 20.2.1 原生 SDK 与工具链锁定

每次发布必须在 release notes 中记录：

1. 微信 Android SDK 版本。
2. 微信 iOS SDK 版本。
3. QQ Android SDK 版本。
4. QQ iOS SDK 版本。
5. Flutter 最低版本。
6. Dart 最低版本。
7. Android Gradle Plugin、Gradle、Kotlin 最低版本。
8. iOS deployment target。
9. Xcode / Swift 最低验证版本。
10. HarmonyOS SDK / Flutter HarmonyOS 版本，若该版本包含 HarmonyOS 能力。

原因：

1. 微信、QQ SDK 的回调、Universal Link、隐私授权和文件分享行为会随版本变化。
2. Android 包可见性、FileProvider、Activity result 行为与 targetSdk / AGP 有关。
3. iOS Universal Link、SceneDelegate、LSApplicationQueriesSchemes 行为与 iOS SDK 和宿主工程配置有关。

---

### 20.3 README 要求

每个包都需要独立 README。

`share_bridge_core` README：

```text
核心理念
安装方式
基础 API
Provider 注册
自定义 UI 用法
```

`share_bridge_widgets` README：

```text
安装方式
默认分享弹窗
自定义样式
自定义渠道
```

`share_bridge_wechat` README：

```text
安装方式
微信开放平台配置
Android 配置
iOS 配置
HarmonyOS 配置状态
网页分享
图片分享
常见问题
```

`share_bridge_qq` README：

```text
安装方式
QQ 互联配置
Android 配置
iOS 配置
HarmonyOS 配置
网页分享
图片分享
常见问题
```

---

## 21. 开发里程碑

### M0：仓库初始化

目标：

1. 创建 Monorepo。
2. 创建四个 package。
3. 配置 lint。
4. 配置 CI。
5. 创建 example。
6. 创建 docs。

交付物：

```text
packages/share_bridge_core
packages/share_bridge_widgets
packages/share_bridge_wechat
packages/share_bridge_qq
examples/basic_example
```

---

### M1：Core MVP

目标：

1. 完成 `ShareChannel`。
2. 完成 `ShareContent`。
3. 完成 `ShareResult`。
4. 完成 `ShareProvider`。
5. 完成 `ShareManager`。
6. 完成单元测试。

交付物：

```text
share_bridge_core 0.1.0-dev
```

---

### M2：微信 Android/iOS 分享

目标：

1. Android 微信网页分享。
2. Android 微信图片分享。
3. iOS 微信网页分享。
4. iOS 微信图片分享。
5. 分享结果回调。
6. 文档配置说明。

交付物：

```text
share_bridge_wechat 0.1.0-dev
```

---

### M3：QQ Android/iOS 分享

目标：

1. Android QQ 网页分享。
2. Android QQ 图片分享。
3. iOS QQ 网页分享。
4. iOS QQ 图片分享。
5. QQ 空间网页分享。
6. QQ 空间图片分享按官方 SDK 当前版本能力验证；若某平台不可稳定支持，MVP 明确返回 `unsupportedContent`。
7. 分享结果回调。
8. 文档配置说明。

交付物：

```text
share_bridge_qq 0.1.0-dev
```

---

### M4：Widgets MVP

目标：

1. 默认底部分享面板。
2. 分享宫格。
3. 自定义渠道。
4. 自定义 icon。
5. 自定义文案。
6. 分享结果回调。

交付物：

```text
share_bridge_widgets 0.1.0-dev
```

---

### M5：HarmonyOS 适配

目标：

1. 验证 Flutter HarmonyOS 插件结构。
2. 接入 QQ HarmonyOS SDK。
3. 验证微信 HarmonyOS 分享能力。
4. 补充 `ohos/` 平台实现。
5. 补充 HarmonyOS 配置文档。
6. 真机测试。

交付物：

```text
share_bridge_qq HarmonyOS support
share_bridge_wechat HarmonyOS support, depending on official SDK availability
```

---

## 22. 风险点

### 22.1 官方 SDK 能力差异

微信、QQ 在 Android、iOS、HarmonyOS 上的能力可能不完全一致。

应对：

1. 使用 `supports()` 做能力判断。
2. 不支持时返回 `unsupportedContent`。
3. 文档中明确平台差异。
4. 不承诺所有平台能力完全一致。

---

### 22.2 回调复杂

微信、QQ 回调依赖 App 生命周期、URL Scheme、Universal Link、Activity、Ability 等配置。

应对：

1. 每个平台单独写接入文档。
2. Example 覆盖完整回调。
3. Native 层统一 result mapper。
4. 常见问题单独整理。

---

### 22.3 用户配置错误

常见错误包括：

```text
Android 签名错误
包名不一致
AppID 错误
URL Scheme 错误
Universal Link 错误
Associated Domains 错误
未配置 queries
未配置回调 Activity
```

应对：

1. 初始化阶段尽量校验。
2. 返回 `configError`。
3. README 提供检查清单。
4. Example 提供最小可运行配置。

---

### 22.4 品牌资源和商标风险

默认 UI 如果内置微信、QQ 官方 Logo，可能涉及品牌使用规范。

应对：

1. widgets 默认不强绑定官方 Logo。
2. 允许用户传入自定义 icon。
3. 文档提示使用方遵守平台品牌规范。
4. 示例项目可以使用文字按钮或占位图标。

---

### 22.5 隐私合规风险

即使本库只做分享，底层官方 SDK 仍可能涉及隐私合规声明。

应对：

1. 提供 `docs/privacy.md`。
2. 支持隐私授权状态传入。
3. 不在用户同意前强制初始化 SDK。
4. 文档提示接入方完善隐私政策。
5. 不采集、不上传、不存储用户个人信息。

---

## 23. MVP 范围

首版 MVP 只做：

```text
share_bridge_core
share_bridge_wechat Android/iOS 网页分享、图片分享
share_bridge_qq Android/iOS 网页分享、QQ 好友图片分享、QQ 空间图片能力验证
share_bridge_widgets 基础分享面板
basic_example
widgets_example
```

首版不做：

```text
微信小程序分享
文本分享
音乐分享
视频分享
文件分享
微博
抖音
系统分享
HarmonyOS 正式支持
复杂主题系统
自动生成分享海报
```

---

## 24. 验收标准

MVP 完成标准：

1. 用户只引入 `share_bridge_core + share_bridge_wechat`，最终项目不包含 QQ SDK。
2. 用户只引入 `share_bridge_core + share_bridge_qq`，最终项目不包含微信 SDK。
3. 用户不引入 `share_bridge_widgets`，可以完全自定义分享 UI。
4. 微信好友网页分享成功。
5. 微信朋友圈网页分享成功。
6. 微信好友图片分享成功。
7. 微信朋友圈图片分享成功。
8. QQ 好友网页分享成功。
9. QQ 空间网页分享成功。
10. QQ 好友图片分享成功。
11. QQ 空间图片分享在官方 SDK 当前版本支持且真机验证通过的平台成功；不可稳定支持的平台返回 `unsupportedContent`。
12. 用户取消分享时返回 `cancelled`。
13. 目标 App 未安装时返回 `appNotInstalled`。
14. 未注册渠道时返回 `unsupportedChannel`。
15. 不支持内容类型时返回 `unsupportedContent`。
16. README 能让新用户完成最小接入。
17. Example 能在真机跑通。

---

## 25. 最终设计结论

本项目应采用以下结构：

```text
share_bridge_core      基础协议层
share_bridge_widgets   可选 UI 层
share_bridge_wechat    微信分享能力层
share_bridge_qq        QQ 分享能力层
```

核心原则：

```text
能力模块化
UI 可选
只做分享
不做登录
不做支付
官方 SDK 作为 Native 底座
Flutter 层提供稳定、轻量、可扩展 API
```

该结构适合开源维护，也适合后续扩展 HarmonyOS、微博、抖音、系统分享等能力。

---

## 26. 参考资料

官方文档：

1. 微信开放平台移动应用文档：https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Resource_Center_Homepage.html
2. 微信 Android 分享与收藏文档：https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Share_and_Favorites/Android.html
3. 微信 iOS 接入指南：https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html
4. QQ 互联分享消息到 QQ：https://wiki.connect.qq.com/分享消息到qq（无需qq登录）
5. QQ 互联分享到 QQ 空间：https://wiki.connect.qq.com/分享到qq空间（无需qq登录）
6. QQ 互联分享功能存储权限适配：https://wiki.connect.qq.com/分享功能存储权限适配
7. QQ 互联 iOS SDK API 使用说明：https://wiki.connect.qq.com/ios_sdk_api_使用说明
8. Android package visibility：https://developer.android.com/training/package-visibility/declaring
9. Apple Associated Domains：https://developer.apple.com/documentation/xcode/supporting-associated-domains
10. Apple Universal Links archive：https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
11. Flutter Platform Channels：https://docs.flutter.dev/platform-integration/platform-channels
12. Flutter packages and federated plugins：https://docs.flutter.dev/packages-and-plugins/developing-packages

开源实现参考：

1. OpenFlutter/fluwx：https://github.com/OpenFlutter/fluwx
2. rxreader/tencent_kit：https://github.com/rxreader/tencent_kit
3. fluttercommunity/share_plus：https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus/share_plus

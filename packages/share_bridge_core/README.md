# share_bridge_core

[English](README_EN.md) | 中文

Share Bridge 的纯 Dart 核心库。

这个包定义分享客户端、分享渠道、分享内容、统一结果码、Provider 协议和 `ShareManager`。它不依赖 Flutter、不依赖原生平台 SDK，也不包含任何 UI。

## 使用示例

```dart
final manager = ShareManager();

await manager.register(myProvider);

final installed = await manager.isInstalled(ShareClient.wechat);

final result = await manager.share(
  channel: ShareChannel.wechatSession,
  content: const ShareContent.webpage(
    title: '标题',
    description: '描述',
    url: 'https://example.com',
  ),
);
```

`ShareClient` 表示真实客户端应用，例如微信或 QQ；`ShareChannel` 表示客户端下的分享目标，例如微信好友、朋友圈、QQ 好友或 QQ 空间。安装检查统一使用 `ShareManager.isInstalled(ShareClient.xxx)`，真实分享时 `ShareManager.share()` 仍会内部处理未安装错误。

`ShareManager.register(provider)` 会立即初始化 provider。宿主 App 应在用户同意隐私政策并完成必要配置后再注册相关 provider。

图片只支持本地文件和内存数据：

```dart
const ShareContent.image(
  image: ShareImageSource.file('/path/to/image.png'),
);
```

网络图片和 Flutter asset 需要宿主 App 自行下载或读取后，再传入本地文件路径或 `Uint8List`。

## 范围

- 不包含微信或 QQ SDK。
- 不包含 MethodChannel 实现。
- 不包含 UI 组件或品牌图标资源。

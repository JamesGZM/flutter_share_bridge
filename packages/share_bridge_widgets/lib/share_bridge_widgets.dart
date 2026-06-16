library;

import 'package:flutter/material.dart';
import 'package:share_bridge_core/share_bridge_core.dart';
import 'package:simple_icons/simple_icons.dart';

export 'package:share_bridge_core/share_bridge_core.dart';

typedef ShareChannelIconBuilder = Widget Function(
  BuildContext context,
  ShareChannel channel,
);

typedef ShareChannelTitleBuilder = String Function(ShareChannel channel);

/// Visual configuration for Share Bridge widgets.
final class ShareBridgeSheetTheme {
  const ShareBridgeSheetTheme({
    this.backgroundColor,
    this.handleColor,
    this.itemForegroundColor,
    this.itemSize = 72,
    this.spacing = 12,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  final Color? backgroundColor;
  final Color? handleColor;
  final Color? itemForegroundColor;
  final double itemSize;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
}

/// Default bottom sheet wrapper around [ShareBridgeGrid].
final class ShareBridgeSheet {
  const ShareBridgeSheet._();

  static Future<ShareResult?> show({
    required BuildContext context,
    required ShareManager manager,
    required ShareContent content,
    List<ShareChannel>? channels,
    ShareBridgeSheetTheme theme = const ShareBridgeSheetTheme(),
    ShareChannelIconBuilder? iconBuilder,
    ShareChannelTitleBuilder? titleBuilder,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<ShareResult>(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints.tightFor(width: width),
      builder: (context) {
        final effectiveChannels =
            channels ?? manager.registeredChannels.toList();
        return _ShareBridgeSheetBody(
          manager: manager,
          content: content,
          channels: effectiveChannels,
          theme: theme,
          iconBuilder: iconBuilder,
          titleBuilder: titleBuilder,
        );
      },
    );
  }
}

/// Embeddable share grid for custom sheets or pages.
class ShareBridgeGrid extends StatelessWidget {
  const ShareBridgeGrid({
    super.key,
    required this.manager,
    required this.content,
    required this.channels,
    this.onResult,
    this.iconBuilder,
    this.titleBuilder,
    this.itemSize = 72,
    this.spacing = 12,
  });

  final ShareManager manager;
  final ShareContent content;
  final List<ShareChannel> channels;
  final ValueChanged<ShareResult>? onResult;
  final ShareChannelIconBuilder? iconBuilder;
  final ShareChannelTitleBuilder? titleBuilder;
  final double itemSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final channel in channels)
          _ShareChannelButton(
            channel: channel,
            size: itemSize,
            iconBuilder: iconBuilder,
            titleBuilder: titleBuilder,
            onPressed: () async {
              final result = await manager.share(
                channel: channel,
                content: content,
              );
              onResult?.call(result);
            },
          ),
      ],
    );
  }
}

class _ShareBridgeSheetBody extends StatelessWidget {
  const _ShareBridgeSheetBody({
    required this.manager,
    required this.content,
    required this.channels,
    required this.theme,
    this.iconBuilder,
    this.titleBuilder,
  });

  final ShareManager manager;
  final ShareContent content;
  final List<ShareChannel> channels;
  final ShareBridgeSheetTheme theme;
  final ShareChannelIconBuilder? iconBuilder;
  final ShareChannelTitleBuilder? titleBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.backgroundColor ?? colorScheme.surface,
          borderRadius: theme.borderRadius,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: theme.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.handleColor ??
                        colorScheme.onSurfaceVariant.withAlpha(92),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                if (channels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '暂无可用分享渠道',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShareBridgeGrid(
                      manager: manager,
                      content: content,
                      channels: channels,
                      itemSize: theme.itemSize,
                      spacing: theme.spacing,
                      iconBuilder: iconBuilder,
                      titleBuilder: titleBuilder,
                      onResult: (result) {
                        Navigator.of(context).pop(result);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareChannelButton extends StatelessWidget {
  const _ShareChannelButton({
    required this.channel,
    required this.size,
    required this.onPressed,
    this.iconBuilder,
    this.titleBuilder,
  });

  final ShareChannel channel;
  final double size;
  final VoidCallback onPressed;
  final ShareChannelIconBuilder? iconBuilder;
  final ShareChannelTitleBuilder? titleBuilder;

  @override
  Widget build(BuildContext context) {
    final title = titleBuilder?.call(channel) ?? _defaultTitle(channel);
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustomIcon = iconBuilder != null;
    return SizedBox(
      width: size,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: hasCustomIcon
                        ? colorScheme.surfaceContainerHighest
                        : _defaultIconBackgroundColor(channel),
                  ),
                  child: Center(
                    child: iconBuilder?.call(context, channel) ??
                        Icon(
                          _defaultIcon(channel),
                          size: 24,
                          color: _defaultIconColor(channel),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultTitle(ShareChannel channel) {
    return switch (channel.id) {
      'wechat.session' => '微信',
      'wechat.timeline' => '朋友圈',
      'qq.friend' => 'QQ',
      'qq.qzone' => 'QQ空间',
      _ => channel.id,
    };
  }

  IconData _defaultIcon(ShareChannel channel) {
    return switch (channel.id) {
      'wechat.session' => SimpleIcons.wechat,
      'wechat.timeline' => SimpleIcons.wechat,
      'qq.friend' => SimpleIcons.qq,
      'qq.qzone' => SimpleIcons.qzone,
      _ => Icons.share,
    };
  }

  Color _defaultIconBackgroundColor(ShareChannel channel) {
    return switch (channel.id) {
      'wechat.session' || 'wechat.timeline' => SimpleIconColors.wechat,
      'qq.friend' => SimpleIconColors.qq,
      'qq.qzone' => SimpleIconColors.qzone,
      _ => Colors.grey,
    };
  }

  Color _defaultIconColor(ShareChannel channel) {
    return switch (channel.id) {
      'qq.qzone' => Colors.black87,
      _ => Colors.white,
    };
  }
}

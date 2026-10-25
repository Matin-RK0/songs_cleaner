import 'package:flutter/material.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/telegram_models.dart';
import 'telegram_chat_avatar.dart';

class TelegramChatTile extends StatelessWidget {
  const TelegramChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onPin,
    this.pinned = false,
    this.recent = false,
  });
  final TelegramChat chat;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final bool pinned;
  final bool recent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Row(
            children: [
              HeroMode(
                enabled: !MediaQuery.disableAnimationsOf(context),
                child: Hero(
                  tag: 'telegram-chat-${chat.id}',
                  child: TelegramChatAvatar(chat: chat),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      pinned
                          ? context.l10n.telegramPinned
                          : recent
                          ? context.l10n.telegramRecent
                          : chat.kind == 'chatTypePrivate'
                          ? context.l10n.telegramConversation
                          : context.l10n.telegramChannelOrGroup,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (onPin != null)
                IconButton(
                  tooltip: pinned
                      ? context.l10n.telegramUnpin
                      : context.l10n.telegramPin,
                  onPressed: onPin,
                  icon: Icon(
                    pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

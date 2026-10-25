import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/telegram_models.dart';
import 'telegram_chat_avatar.dart';
import '../../application/telegram_chat_summary_provider.dart';
import '../../application/telegram_download_controller.dart';
import '../../application/telegram_preferences_controller.dart';
import '../../domain/telegram_download.dart';

class TelegramChatEntry extends ConsumerWidget {
  const TelegramChatEntry({super.key, required this.chat, required this.onTap});
  final TelegramChat chat;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(
      telegramPreferencesProvider.select(
        (value) => (value['pins'] as List? ?? []).contains(chat.id),
      ),
    );
    final recent = ref.watch(
      telegramPreferencesProvider.select(
        (value) => (value['recent'] as List? ?? []).contains(chat.id),
      ),
    );
    final count = ref.watch(telegramChatLocalCountProvider(chat.id)).value;
    final active = ref.watch(
      telegramDownloadsProvider.select(
        (jobs) => jobs.values
            .where(
              (job) =>
                  job.audio.chatId == chat.id &&
                  (job.active || job.phase == TelegramDownloadPhase.queued),
            )
            .length,
      ),
    );
    return TelegramChatTile(
      chat: chat,
      onTap: onTap,
      pinned: pinned,
      recent: recent,
      localCount: count,
      downloading: active > 0,
      onPin: () {
        final changed = ref
            .read(telegramPreferencesProvider.notifier)
            .pin(chat.id);
        if (!changed) showAppSnackBar(context, context.l10n.telegramPinLimit);
      },
    );
  }
}

class TelegramChatTile extends StatelessWidget {
  const TelegramChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onPin,
    this.pinned = false,
    this.recent = false,
    this.localCount,
    this.downloading = false,
  });
  final TelegramChat chat;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final bool pinned;
  final bool recent;
  final int? localCount;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
        side: BorderSide(
          color: pinned ? colors.primaryContainer : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onPin,
        borderRadius: AppRadius.xl,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Row(
            children: [
              Stack(
                children: [
                  HeroMode(
                    enabled: !MediaQuery.disableAnimationsOf(context),
                    child: Hero(
                      tag: 'telegram-chat-${chat.id}',
                      child: TelegramChatAvatar(chat: chat),
                    ),
                  ),
                  if (downloading)
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.download_rounded,
                            size: AppSpacing.md,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      style: theme.textTheme.titleMedium,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (localCount != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.offline_pin_outlined,
                              size: AppSpacing.md,
                              color: colors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                context.l10n.telegramLocalCount(localCount!),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    color: pinned ? colors.primary : colors.onSurfaceVariant,
                  ),
                )
              else
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

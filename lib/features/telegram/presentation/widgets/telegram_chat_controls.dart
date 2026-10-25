import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/telegram_chat_local_inventory_provider.dart';
import '../../application/telegram_controller.dart';

class TelegramChatControls extends ConsumerWidget {
  const TelegramChatControls({
    super.key,
    required this.chatId,
    required this.connected,
    required this.queryController,
  });

  final int chatId;
  final bool connected;
  final TextEditingController queryController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final songs = ref.watch(telegramChatSongsProvider(chatId));
    final count = ref.watch(telegramChatTotalLocalCountProvider(chatId));
    final controller = ref.read(telegramChatProvider(chatId).notifier);
    return Padding(
      padding: AppSpacing.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: AppRadius.xl,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: AppSpacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.library_music_rounded, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.telegramLocalCount(count),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (!connected) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Tooltip(
                          message: l10n.telegramOffline,
                          child: Icon(
                            Icons.cloud_off_rounded,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: songs.isEmpty
                              ? null
                              : () => ref
                                    .read(playerProvider.notifier)
                                    .playFromList(songs, startIndex: 0),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            l10n.telegramPlayLocal,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        tooltip: l10n.shuffleAll,
                        onPressed: songs.isEmpty
                            ? null
                            : () => ref
                                  .read(playerProvider.notifier)
                                  .playAllShuffled(songs),
                        icon: const Icon(Icons.shuffle_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: queryController,
            builder: (context, value, _) => TextField(
              controller: queryController,
              onChanged: controller.search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: l10n.telegramSearchMusic,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? Tooltip(
                        message: l10n.telegramLoadedSearchHint,
                        child: const Icon(Icons.info_outline_rounded),
                      )
                    : IconButton(
                        tooltip: l10n.telegramClearSearch,
                        onPressed: () {
                          queryController.clear();
                          controller.search('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TelegramChatFilters extends ConsumerWidget {
  const TelegramChatFilters({super.key, required this.chatId});

  final int chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final filters = ref.watch(
      telegramChatProvider(chatId).select(
        (s) => (localOnly: s.localOnly, activeOnly: s.activeOnly, sort: s.sort),
      ),
    );
    final hasTracks = ref.watch(
      telegramChatTracksProvider(chatId).select((tracks) => tracks.isNotEmpty),
    );
    final controller = ref.read(telegramChatProvider(chatId).notifier);
    final sortLabel = switch (filters.sort) {
      'oldest' => l10n.telegramOldest,
      'title' => l10n.telegramByTitle,
      _ => l10n.telegramNewest,
    };
    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screenPadding,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(l10n.telegramLocal),
                      showCheckmark: false,
                      selected: filters.localOnly && !filters.activeOnly,
                      onSelected: (_) => controller.setLocalOnly(true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text(l10n.telegramAllAudio),
                      showCheckmark: false,
                      selected: !filters.localOnly && !filters.activeOnly,
                      onSelected: (_) => controller.setLocalOnly(false),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(
                      label: Text(l10n.telegramDownloads),
                      showCheckmark: false,
                      selected: filters.activeOnly,
                      onSelected: (_) => controller.setActiveOnly(),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '${l10n.sortLabel}: $sortLabel',
              icon: const Icon(Icons.sort_rounded),
              initialValue: filters.sort,
              onSelected: controller.setSort,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'newest',
                  checked: filters.sort == 'newest',
                  child: Text(l10n.telegramNewest),
                ),
                CheckedPopupMenuItem(
                  value: 'oldest',
                  checked: filters.sort == 'oldest',
                  child: Text(l10n.telegramOldest),
                ),
                CheckedPopupMenuItem(
                  value: 'title',
                  checked: filters.sort == 'title',
                  child: Text(l10n.telegramByTitle),
                ),
              ],
            ),
            IconButton(
              tooltip: l10n.telegramSelect,
              onPressed: !hasTracks
                  ? null
                  : () => controller.toggleSelection(
                      ref
                          .read(telegramChatTracksProvider(chatId))
                          .first
                          .audio
                          .key,
                    ),
              icon: const Icon(Icons.checklist_rounded),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

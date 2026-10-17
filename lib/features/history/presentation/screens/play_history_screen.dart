import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/presentation/widgets/song_tile.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/models/resolved_history_entry.dart';
import '../../application/providers/play_history_controller.dart';
import '../../application/providers/resolved_history_provider.dart';

class PlayHistoryScreen extends ConsumerWidget {
  const PlayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(resolvedHistoryProvider);
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: context.l10n.clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: entries.isEmpty
          ? AppEmptyState(
              icon: Icons.history_rounded,
              title: context.l10n.historyEmptyTitle,
              message: context.l10n.historyEmptyMessage,
            )
          : _HistoryList(entries: entries, currentSongId: currentId),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.clearHistoryTitle),
        content: Text(context.l10n.clearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.clearAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(playHistoryProvider.notifier).clear();
    }
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.entries, required this.currentSongId});

  final List<ResolvedHistoryEntry> entries;
  final int? currentSongId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        final previous = index == 0 ? null : entries[index - 1];
        final showHeader =
            previous == null ||
            !_sameDay(previous.entry.playedAt, item.entry.playedAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  _dayLabel(context, item.entry.playedAt),
                  style: AppTypography.sectionLabel.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            SongTile(
              song: item.song,
              isCurrent: item.song.id == currentSongId,
              trailingLabel: MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(TimeOfDay.fromDateTime(item.entry.playedAt)),
              onTap: () => ref.read(playerProvider.notifier).playFromList([
                item.song,
              ], startIndex: 0),
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (_sameDay(now, date)) return context.l10n.today;
    final yesterday = now.subtract(const Duration(days: 1));
    if (_sameDay(yesterday, date)) return context.l10n.yesterday;
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}

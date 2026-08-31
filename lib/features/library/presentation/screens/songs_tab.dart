import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/providers/library_controller.dart';
import '../../domain/value_objects/song_sort.dart';
import '../widgets/permission_gate_view.dart';
import '../widgets/song_list_view.dart';

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final currentId = ref.watch(
      playerProvider.select((state) => state.current?.id),
    );

    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(context, ref, error),
      data: (state) {
        if (state.songs.isEmpty) {
          return AppEmptyState(
            icon: Icons.library_music_rounded,
            title: context.l10n.emptyLibraryTitle,
            message: context.l10n.emptyLibraryMessage,
          );
        }
        return Column(
          children: [
            Expanded(
              child: state.visibleSongs.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.noResultsTitle,
                      message: context.l10n.noResultsMessage,
                    )
                  : SongListView(
                      songs: state.visibleSongs,
                      currentSongId: currentId,
                      controller: widget.scrollController,
                      itemExtent: 76,
                      onSongTap: (songs, index) => ref
                          .read(playerProvider.notifier)
                          .playFromList(songs, startIndex: index),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final l10n = context.l10n;
    if (error is PermissionFailure) {
      return PermissionGateView(
        onRetry: () async {
          await ref.read(libraryProvider.notifier).refresh();
        },
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppErrorState(
            title: l10n.errorLoadFailedTitle,
            message: l10n.errorLoadFailedMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryActionButton(
            label: l10n.retry,
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(libraryProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for choosing the song list ordering.
Future<void> showSortSheet(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final current = ref.read(libraryProvider).value?.sort ?? SongSort.titleAsc;

  final selected = await showModalBottomSheet<SongSort>(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.sortLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textHigh,
              ),
            ),
          ),
          RadioGroup<SongSort>(
            groupValue: current,
            onChanged: (value) => Navigator.of(sheetContext).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final sort in SongSort.values)
                  RadioListTile<SongSort>(
                    value: sort,
                    activeColor: AppColors.primary,
                    title: Text(_sortLabel(l10n, sort)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );

  if (selected != null) {
    ref.read(libraryProvider.notifier).setSort(selected);
  }
}

String _sortLabel(AppLocalizations l10n, SongSort sort) => switch (sort) {
  SongSort.titleAsc => l10n.sortByTitle,
  SongSort.artistAsc => l10n.sortByArtist,
  SongSort.dateAddedDesc => l10n.sortByDateAdded,
  SongSort.durationDesc => l10n.sortByDuration,
};

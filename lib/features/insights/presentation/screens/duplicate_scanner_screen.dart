import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/file_size_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../../library/domain/entities/song.dart';
import '../../../library/presentation/widgets/artwork_image.dart';
import '../../application/providers/library_insights_provider.dart';
import '../../domain/entities/duplicate_group.dart';

class DuplicateScannerScreen extends ConsumerWidget {
  const DuplicateScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(
      libraryInsightsProvider.select((insights) => insights.duplicateGroups),
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.duplicateScannerTitle)),
      body: groups.isEmpty
          ? AppEmptyState(
              icon: Icons.library_add_check_rounded,
              title: context.l10n.noDuplicatesTitle,
              message: context.l10n.noDuplicatesMessage,
            )
          : ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              itemCount: groups.length,
              itemBuilder: (context, index) =>
                  _DuplicateGroupTile(group: groups[index], index: index),
            ),
    );
  }
}

class _DuplicateGroupTile extends ConsumerWidget {
  const _DuplicateGroupTile({required this.group, required this.index});

  final DuplicateGroup group;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      initiallyExpanded: index == 0,
      leading: ArtworkImage(songId: group.recommendedSong.id, size: 48),
      title: Text(
        group.recommendedSong.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.emphasisTitle.copyWith(
          color: context.colors.textHigh,
        ),
      ),
      subtitle: Text(
        context.l10n.duplicateGroupSummary(
          group.songs.length,
          group.recoverableBytes.readableFileSize,
        ),
      ),
      children: [
        for (final song in group.songs)
          _DuplicateSongTile(
            song: song,
            recommended: song.id == group.recommendedSong.id,
            onDelete: () => _delete(context, ref, song),
          ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Song song) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.deleteConfirmTitle,
      message: context.l10n.deleteDuplicateMessage(song.title),
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
    );
    if (confirmed && context.mounted) {
      await deleteSongFlow(context, ref, song);
    }
  }
}

class _DuplicateSongTile extends StatelessWidget {
  const _DuplicateSongTile({
    required this.song,
    required this.recommended,
    required this.onDelete,
  });

  final Song song;
  final bool recommended;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsetsDirectional.only(
      start: AppSpacing.xl,
      end: AppSpacing.sm,
    ),
    leading: Icon(
      recommended ? Icons.verified_rounded : Icons.audio_file_rounded,
      color: recommended ? context.colors.success : context.colors.textLow,
    ),
    title: Text(
      '${song.fileExtension.toUpperCase()} · ${song.sizeBytes.readableFileSize}',
      style: AppTypography.listTitle.copyWith(color: context.colors.textHigh),
    ),
    subtitle: Text(
      '${song.duration.mmss} · ${song.path}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: recommended
        ? Tooltip(
            message: context.l10n.recommendedToKeep,
            child: Icon(Icons.shield_outlined, color: context.colors.success),
          )
        : IconButton(
            tooltip: context.l10n.deleteAction,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: context.colors.danger,
            ),
          ),
  );
}

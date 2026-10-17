import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/file_size_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../app/router/route_names.dart';
import '../../../file_manager/infrastructure/file_manager_service.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../application/providers/library_controller.dart';
import '../../domain/entities/song.dart';
import '../../application/providers/library_providers.dart';
import '../../application/song_share_service.dart';
import '../../application/ringtone_service.dart';
import '../widgets/artwork_image.dart';

class SongDetailsScreen extends ConsumerWidget {
  const SongDetailsScreen({super.key, required this.songId});

  final int songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(songsByIdProvider)[songId];
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.songDetailsTitle)),
        body: AppEmptyState(
          icon: Icons.music_off_rounded,
          title: context.l10n.songNotFound,
        ),
      );
    }
    final modified = song.dateModifiedSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(song.dateModifiedSeconds * 1000)
        : null;
    final isQueued = ref.watch(
      playerProvider.select(
        (state) => state.songs.any((item) => item.id == song.id),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.songDetailsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.editTagsTitle,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(RouteNames.tagEditor, arguments: song.id),
          ),
          IconButton(
            tooltip: context.l10n.renameFileTitle,
            icon: const Icon(Icons.drive_file_rename_outline_rounded),
            onPressed: isQueued ? null : () => _rename(context, ref, song),
          ),
          IconButton(
            tooltip: context.l10n.shareSongAction,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context, song),
          ),
          IconButton(
            tooltip: context.l10n.setAsRingtoneAction,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => _setAsRingtone(context, song),
          ),
          PopupMenuButton<_FileAction>(
            tooltip: context.l10n.fileActionsTitle,
            onSelected: (action) =>
                _transfer(context, ref, song, move: action == _FileAction.move),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _FileAction.copy,
                child: Text(context.l10n.copyFileAction),
              ),
              PopupMenuItem(
                value: _FileAction.move,
                enabled: !isQueued,
                child: Text(context.l10n.moveFileAction),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: RepaintBoundary(
              child: Hero(
                tag: 'song-details-art-${song.id}',
                child: ArtworkImage(
                  songId: song.id,
                  size: 180,
                  borderRadius: AppRadius.xl,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            song.title,
            textAlign: TextAlign.center,
            style: AppTypography.playerTitle.copyWith(
              color: context.colors.textHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailsCard(
            rows: [
              _DetailRow(
                context.l10n.artistLabel,
                _fallback(context, song.artist),
              ),
              _DetailRow(
                context.l10n.albumLabel,
                _fallback(context, song.album),
              ),
              _DetailRow(
                context.l10n.genreLabel,
                _fallback(context, song.genre),
              ),
              _DetailRow(
                context.l10n.composerLabel,
                _fallback(context, song.composer),
              ),
              _DetailRow(
                context.l10n.trackNumberLabel,
                song.trackNumber > 0
                    ? '${song.trackNumber}'
                    : context.l10n.unknownValue,
              ),
              _DetailRow(context.l10n.durationLabel, song.duration.mmss),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailsCard(
            rows: [
              _DetailRow(
                context.l10n.fileFormatLabel,
                song.fileExtension.isEmpty
                    ? context.l10n.unknownValue
                    : song.fileExtension.toUpperCase(),
              ),
              _DetailRow(
                context.l10n.fileSizeLabel,
                song.sizeBytes.readableFileSize,
              ),
              _DetailRow(
                context.l10n.folderLabel,
                _fallback(context, song.folderPath),
              ),
              _DetailRow(context.l10n.filePathLabel, song.path),
              if (modified != null)
                _DetailRow(
                  context.l10n.modifiedDateLabel,
                  MaterialLocalizations.of(context).formatMediumDate(modified),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, Song song) async {
    try {
      final shared = await const SongShareService().share(song);
      if (shared && context.mounted) {
        showAppSnackBar(context, context.l10n.songShareOpened);
      }
    } on PlatformException {
      if (context.mounted) {
        showAppSnackBar(context, context.l10n.songShareFailed, error: true);
      }
    }
  }

  Future<void> _setAsRingtone(BuildContext context, Song song) async {
    try {
      await const RingtoneService().setAsRingtone(song);
      if (context.mounted) {
        showAppSnackBar(context, context.l10n.ringtoneSetToast);
      }
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        error.code == 'WRITE_SETTINGS_REQUIRED'
            ? context.l10n.ringtonePermissionRequired
            : context.l10n.ringtoneSetFailed,
        error: true,
      );
    }
  }

  String _fallback(BuildContext context, String value) =>
      value.isEmpty ? context.l10n.unknownValue : value;

  Future<void> _rename(BuildContext context, WidgetRef ref, Song song) async {
    final controller = TextEditingController(text: _baseName(song.path));
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.renameFileTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.fileNameLabel),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.l10n.saveAction),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    try {
      await ref.read(fileManagerServiceProvider).rename(song, value);
      await ref.read(libraryProvider.notifier).refresh();
      if (!context.mounted) return;
      showAppSnackBar(context, context.l10n.fileRenamedToast);
    } on FileManagerValidationException catch (error) {
      if (!context.mounted) return;
      showAppSnackBar(context, _renameError(context, error.code), error: true);
    } on FileManagerOperationException {
      if (!context.mounted) return;
      showAppSnackBar(context, context.l10n.fileRenameFailed, error: true);
    }
  }

  String _renameError(BuildContext context, String code) => switch (code) {
    'fileNameRequired' => context.l10n.fileNameRequired,
    'fileNameInvalid' => context.l10n.fileNameInvalid,
    'fileExtensionCannotChange' => context.l10n.fileExtensionCannotChange,
    'fileAlreadyExists' => context.l10n.fileAlreadyExists,
    _ => context.l10n.fileRenameFailed,
  };

  String _baseName(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  Future<void> _transfer(
    BuildContext context,
    WidgetRef ref,
    Song song, {
    required bool move,
  }) async {
    final parent = File(song.path).parent.path;
    final destination = await Navigator.of(
      context,
    ).pushNamed(RouteNames.folderPicker, arguments: parent);
    if (destination is! String || !context.mounted) return;
    try {
      final service = ref.read(fileManagerServiceProvider);
      if (move) {
        await service.move(song, destination);
      } else {
        await service.copy(song, destination);
      }
      await ref.read(libraryProvider.notifier).refresh();
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        move ? context.l10n.fileMovedToast : context.l10n.fileCopiedToast,
      );
    } on FileManagerValidationException catch (error) {
      if (!context.mounted) return;
      showAppSnackBar(context, _renameError(context, error.code), error: true);
    } on FileManagerOperationException {
      if (!context.mounted) return;
      showAppSnackBar(context, context.l10n.fileTransferFailed, error: true);
    }
  }
}

enum _FileAction { copy, move }

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.colors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index < rows.length - 1) Divider(color: context.colors.outline),
          ],
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SelectableText(
            value,
            style: AppTypography.body.copyWith(color: context.colors.textHigh),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../library/application/providers/library_controller.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/domain/entities/song.dart';
import '../../../lyrics/application/providers/lyrics_provider.dart';
import '../../domain/entities/tag_draft.dart';
import '../../domain/services/tag_editor_validator.dart';
import '../../infrastructure/tag_editor_service.dart';

class TagEditorScreen extends ConsumerStatefulWidget {
  const TagEditorScreen({super.key, required this.songId});

  final int songId;

  @override
  ConsumerState<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends ConsumerState<TagEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _album = TextEditingController();
  final _genre = TextEditingController();
  final _composer = TextEditingController();
  final _track = TextEditingController();
  final _lyrics = TextEditingController();
  int? _initializedSongId;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    _composer.dispose();
    _track.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(songsByIdProvider)[widget.songId];
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.tagEditorTitle)),
        body: Center(child: Text(context.l10n.songNotFound)),
      );
    }
    if (_initializedSongId != song.id) {
      _initializedSongId = song.id;
      _title.text = song.title;
      _artist.text = song.artist;
      _album.text = song.album;
      _genre.text = song.genre;
      _composer.text = song.composer;
      _track.text = song.trackNumber == 0 ? '' : '${song.trackNumber}';
    }
    ref.listen(lyricsProvider(song), (_, next) {
      next.whenData((lines) {
        if (_lyrics.text.isEmpty) {
          _lyrics.text = lines
              .map((line) => '${_formatTimestamp(line.timestamp)}${line.text}')
              .join('\n');
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tagEditorTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.saveAction,
            onPressed: _saving ? null : () => _save(song),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _field(_title, context.l10n.titleLabel, required: true),
            _field(_artist, context.l10n.artistLabel),
            _field(_album, context.l10n.albumLabel),
            _field(_genre, context.l10n.genreLabel),
            _field(_composer, context.l10n.composerLabel),
            _field(
              _track,
              context.l10n.trackNumberLabel,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: context.colors.surfaceHigh,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lyrics_outlined,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          context.l10n.lyricsTitle,
                          style: AppTypography.sectionTitle.copyWith(
                            color: context.colors.textHigh,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _lyrics,
                      minLines: 8,
                      maxLines: 18,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: context.l10n.lyricsEditorHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(song),
              icon: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: _saving
                    ? const SizedBox.square(
                        key: ValueKey('saving'),
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, key: ValueKey('save')),
              ),
              label: Text(context.l10n.saveAction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required && controller.text.trim().isEmpty
          ? (_) => context.l10n.titleRequired
          : null,
    ),
  );

  Future<void> _save(Song song) async {
    if (!_formKey.currentState!.validate()) return;
    final draft = TagDraft(
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
      genre: _genre.text,
      composer: _composer.text,
      trackNumber: int.tryParse(_track.text.trim()) ?? 0,
      lyrics: _lyrics.text,
    );
    final validation = TagEditorValidator.validate(draft);
    if (validation != null) {
      showAppSnackBar(context, _validationMessage(validation), error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(tagEditorServiceProvider).save(song, draft);
      await ref.read(libraryProvider.notifier).refresh();
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.tagsSavedToast);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.tagsSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _validationMessage(String code) => switch (code) {
    'titleRequired' => context.l10n.titleRequired,
    'trackNumberInvalid' => context.l10n.trackNumberInvalid,
    _ => context.l10n.tagsSaveFailed,
  };

  String _formatTimestamp(Duration timestamp) =>
      '[${timestamp.inMinutes.toString().padLeft(2, '0')}:${(timestamp.inSeconds % 60).toString().padLeft(2, '0')}.${(timestamp.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0')}]';
}

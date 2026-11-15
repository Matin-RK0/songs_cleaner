import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_player_metrics.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cleanup/presentation/cleanup_flow.dart';
import '../../application/providers/player_controller.dart';
import '../../application/providers/player_preferences_controller.dart';
import '../widgets/playback_options_sheet.dart';
import '../widgets/player_actions.dart';
import '../widgets/player_layout.dart';
import '../widgets/player_icon.dart';
import '../widgets/player_state_views.dart';
import '../widgets/swipe_down_to_dismiss.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((state) => state.current));
    final hideQuickDelete = ref.watch(hideQuickDeleteProvider);
    return SwipeDownToDismiss(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: song == null
              ? const NothingPlayingView()
              : PlayerLayout(
                  song: song,
                  hideQuickDelete: hideQuickDelete,
                  useHero: true,
                  header: const _HeaderBar(),
                  actions: PlayerActions(song: song),
                ),
        ),
      ),
    );
  }
}

enum _PlayerMenu { delete, details, lyrics, options, settings }

class _HeaderBar extends ConsumerWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.backTooltip,
            color: context.colors.primary,
            iconSize: AppPlayerMetrics.icon,
            icon: const PlayerIcon(PlayerGlyph.collapse),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.equalizerTitle,
            color: context.colors.primary,
            iconSize: AppPlayerMetrics.icon,
            icon: const PlayerIcon(PlayerGlyph.equalizer),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.equalizer),
          ),
          PopupMenuButton<_PlayerMenu>(
            tooltip: l10n.playbackOptionsTitle,
            borderRadius: AppRadius.xl,
            color: context.colors.surfaceElevated,
            iconSize: AppPlayerMetrics.icon,
            icon: IconTheme(
              data: IconThemeData(
                color: context.colors.primary,
                size: AppPlayerMetrics.icon,
              ),
              child: const PlayerIcon(PlayerGlyph.more),
            ),
            onSelected: (action) {
              switch (action) {
                case _PlayerMenu.delete:
                  final song = ref.read(playerProvider).current;
                  if (song != null) {
                    deleteSongFlow(context, ref, song, useTrash: false);
                  }
                case _PlayerMenu.details:
                  final song = ref.read(playerProvider).current;
                  if (song != null) {
                    Navigator.of(context)
                        .pushNamed(RouteNames.songDetails, arguments: song.id);
                  }
                case _PlayerMenu.lyrics:
                  final song = ref.read(playerProvider).current;
                  if (song != null) {
                    Navigator.of(context)
                        .pushNamed(RouteNames.lyrics, arguments: song);
                  }
                case _PlayerMenu.options:
                  showPlaybackOptionsSheet(context, ref);
                case _PlayerMenu.settings:
                  Navigator.of(context).pushNamed(RouteNames.settings);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _PlayerMenu.delete,
                child: Text(l10n.deleteAction),
              ),
              PopupMenuItem(
                value: _PlayerMenu.details,
                child: Text(l10n.songDetailsTitle),
              ),
              PopupMenuItem(
                value: _PlayerMenu.lyrics,
                child: Text(l10n.lyricsTitle),
              ),
              PopupMenuItem(
                value: _PlayerMenu.options,
                child: Text(l10n.playbackOptionsTitle),
              ),
              PopupMenuItem(
                value: _PlayerMenu.settings,
                child: Text(l10n.settingsTitle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

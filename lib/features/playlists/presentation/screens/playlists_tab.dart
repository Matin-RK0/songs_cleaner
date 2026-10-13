import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../library/application/providers/library_stats_controller.dart';
import '../../application/providers/playlists_controller.dart';
import '../../domain/entities/smart_playlist.dart';
import '../widgets/playlist_artwork.dart';
import '../widgets/playlist_card.dart';
import '../widgets/playlist_name_sheet.dart';

/// Playlists tab: smart playlists (derived) plus the user's custom playlists.
class PlaylistsTab extends ConsumerWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final custom = ref.watch(playlistsProvider);
    final songs = ref.watch(allSongsProvider);
    final stats = ref.watch(libraryStatsProvider);

    final likedCount = songs.where((song) => stats.isFavorite(song.id)).length;
    final mostPlayedCount = songs
        .where((song) => stats.playCount(song.id) > 0)
        .length;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _SectionHeader(title: l10n.smartPlaylistsSection),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 196,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.md,
                end: AppSpacing.md,
              ),
              children: [
                _SmartPlaylistCard(
                  title: l10n.smartLikedTitle,
                  count: likedCount,
                  icon: Icons.favorite_rounded,
                  accent: context.colors.danger,
                  onTap: () => _openSmart(context, SmartPlaylistKind.liked),
                ),
                const SizedBox(width: AppSpacing.md),
                _SmartPlaylistCard(
                  title: l10n.smartRecentTitle,
                  count: songs.length,
                  icon: Icons.fiber_new_rounded,
                  accent: context.colors.primary,
                  onTap: () =>
                      _openSmart(context, SmartPlaylistKind.recentlyAdded),
                ),
                const SizedBox(width: AppSpacing.md),
                _SmartPlaylistCard(
                  title: l10n.smartMostPlayedTitle,
                  count: mostPlayedCount,
                  icon: Icons.local_fire_department_rounded,
                  accent: context.colors.accent,
                  onTap: () =>
                      _openSmart(context, SmartPlaylistKind.mostPlayed),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.myPlaylistsSection,
            trailing: IconButton(
              tooltip: l10n.newPlaylist,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _createPlaylist(context, ref),
            ),
          ),
        ),
        if (custom.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  AppEmptyState(
                    icon: Icons.queue_music_rounded,
                    title: l10n.playlistsEmptyTitle,
                    message: l10n.playlistsEmptyMessage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryActionButton(
                    label: l10n.newPlaylist,
                    icon: Icons.add_rounded,
                    onPressed: () => _createPlaylist(context, ref),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl + 72,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.74,
              ),
              delegate: SliverChildBuilderDelegate(childCount: custom.length, (
                context,
                index,
              ) {
                final playlist = custom[index];
                return PlaylistCard(
                  title: playlist.name,
                  subtitle: l10n.songCountLabel(playlist.songCount),
                  cover: PlaylistArtwork(
                    songIds: playlist.songIds,
                    expand: true,
                  ),
                  onTap: () => _openCustom(context, playlist.id),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _openCustom(BuildContext context, String playlistId) {
    Navigator.of(context).pushNamed(
      RouteNames.playlistDetail,
      arguments: PlaylistDetailArgs.custom(playlistId),
    );
  }

  void _openSmart(BuildContext context, SmartPlaylistKind kind) {
    Navigator.of(context).pushNamed(
      RouteNames.playlistDetail,
      arguments: PlaylistDetailArgs.smart(kind),
    );
  }

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showPlaylistNameSheet(
      context: context,
      title: l10n.newPlaylist,
      actionLabel: l10n.createAction,
    );
    if (name == null) return;
    final playlist = await ref.read(playlistsProvider.notifier).create(name);
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.playlistCreatedToast(playlist.name));
  }
}

/// Section title with an optional trailing action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: context.colors.textHigh,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SmartPlaylistCard extends StatelessWidget {
  const _SmartPlaylistCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 148,
      child: PlaylistCard(
        title: title,
        subtitle: context.l10n.songCountLabel(count),
        cover: DecoratedBox(
          decoration: BoxDecoration(color: colors.surfaceHigh),
          child: Center(child: Icon(icon, size: 44, color: accent)),
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/providers/library_controller.dart';
import '../../application/providers/library_providers.dart';
import '../widgets/artwork_image.dart';

/// Shared list for the artists and albums tabs.
class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key, required this.isArtists});

  final bool isArtists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final library = ref.watch(libraryProvider);

    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          l10n.errorLoadFailedTitle,
          style: const TextStyle(color: AppColors.textMedium),
        ),
      ),
      data: (_) {
        final groups = isArtists
            ? ref.watch(artistGroupsProvider)
            : ref.watch(albumGroupsProvider);
        if (groups.isEmpty) {
          return Center(child: Text(l10n.emptyLibraryTitle));
        }
        return ListView.builder(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
          physics: const ClampingScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final name = group.isUnknown
                ? (isArtists ? l10n.unknownArtist : l10n.unknownAlbum)
                : group.name;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              leading: ArtworkImage(songId: group.coverSongId, size: 52),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(l10n.songCountLabel(group.songCount)),
              onTap: () {
                Navigator.of(context).pushNamed(
                  RouteNames.groupSongs,
                  arguments: GroupSongsArgs(
                    isArtist: isArtists,
                    id: group.id,
                    title: name,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

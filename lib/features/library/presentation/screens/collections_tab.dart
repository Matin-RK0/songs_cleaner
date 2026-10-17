import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../application/providers/library_controller.dart';
import '../../application/providers/library_providers.dart';
import '../../domain/entities/song_collection.dart';
import '../widgets/artwork_image.dart';

class CollectionsTab extends ConsumerWidget {
  const CollectionsTab({super.key, required this.kind});

  final SongCollectionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(context.l10n.errorLoadFailedTitle)),
      data: (_) {
        final collections = kind == SongCollectionKind.genre
            ? ref.watch(genreCollectionsProvider)
            : ref.watch(folderCollectionsProvider);
        if (collections.isEmpty) {
          return AppEmptyState(
            icon: kind == SongCollectionKind.genre
                ? Icons.category_outlined
                : Icons.folder_off_outlined,
            title: context.l10n.emptyLibraryTitle,
            message: context.l10n.noCollectionsMessage,
          );
        }
        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.sm,
            end: AppSpacing.sm,
            bottom: AppSpacing.xl,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            final title = collection.name.isEmpty
                ? kind == SongCollectionKind.genre
                      ? context.l10n.unknownGenre
                      : context.l10n.unknownFolder
                : collection.name;
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: Material(
                color: context.colors.surface,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  leading: ArtworkImage(
                    songId: collection.coverSongId,
                    size: 52,
                    borderRadius: AppRadius.sm,
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.songTitle.copyWith(
                      color: context.colors.textHigh,
                    ),
                  ),
                  subtitle: Text(
                    kind == SongCollectionKind.folder &&
                            collection.songs.first.folderPath.isNotEmpty
                        ? collection.songs.first.folderPath
                        : context.l10n.songCountLabel(collection.songCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_left_rounded,
                    color: context.colors.textLow,
                  ),
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteNames.collectionSongs,
                    arguments: CollectionSongsArgs(
                      kind: kind,
                      key: collection.key,
                      title: title,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

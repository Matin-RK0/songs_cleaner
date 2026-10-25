import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/file_size_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../application/telegram_controller.dart';
import '../../application/telegram_download_controller.dart';
import '../../application/telegram_preferences_controller.dart';
import 'telegram_download_sheet.dart';
import 'telegram_feedback.dart';
import 'telegram_track_tile.dart';
import 'telegram_selection_overlay.dart';

class TelegramChatLibrary extends ConsumerStatefulWidget {
  const TelegramChatLibrary({
    super.key,
    required this.chatId,
    required this.connected,
  });
  final int chatId;
  final bool connected;
  @override
  ConsumerState<TelegramChatLibrary> createState() =>
      _TelegramChatLibraryState();
}

class _TelegramChatLibraryState extends ConsumerState<TelegramChatLibrary> {
  late final ScrollController _scroll;
  late final TextEditingController _query;
  bool _restoredScroll = false;
  @override
  void initState() {
    super.initState();
    final saved = ref
        .read(telegramPreferencesProvider.notifier)
        .chat(widget.chatId);
    _scroll = ScrollController(
      initialScrollOffset: (saved['offset'] as num? ?? 0).toDouble(),
    );
    _query = TextEditingController(text: saved['query'] as String? ?? '');
  }

  @override
  void dispose() {
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.chatId;
    final state = ref.watch(telegramChatProvider(id));
    final tracks = ref.watch(telegramChatTracksProvider(id));
    final songs = ref.watch(telegramChatSongsProvider(id));
    final controller = ref.read(telegramChatProvider(id).notifier);
    final l10n = context.l10n;
    ref.listen(telegramChatProvider(id).select((s) => s.query), (_, value) {
      if (_query.text != value) {
        _query.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    });
    ref.listen(telegramChatProvider(id).select((s) => s.busy), (_, busy) {
      if (busy || _restoredScroll) return;
      _restoredScroll = true;
      final offset =
          ref.read(telegramPreferencesProvider.notifier).chat(id)['offset']
              as num? ??
          0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.jumpTo(
            offset.toDouble().clamp(0, _scroll.position.maxScrollExtent),
          );
        }
      });
    });
    return PopScope(
      canPop: state.selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.clearSelection();
      },
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (notification) {
                  if (_scroll.hasClients) {
                    ref.read(telegramPreferencesProvider.notifier).updateChat(
                      id,
                      {'offset': _scroll.offset},
                    );
                    if (widget.connected &&
                        _scroll.position.extentAfter <
                            AppSpacing.iconHero * 4 &&
                        !state.busy &&
                        state.nextId != 0) {
                      controller.refresh(more: true);
                    }
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scroll,
                  key: PageStorageKey('telegram-audio-$id'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppSpacing.allMd,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.telegramLocalCount(songs.length),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (ref.watch(telegramLocalMatchCountProvider(id)) >
                                0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.telegramLocalMatchesCount(
                                  ref.watch(
                                    telegramLocalMatchCountProvider(id),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                FilledButton.icon(
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () => ref
                                            .read(playerProvider.notifier)
                                            .playFromList(songs, startIndex: 0),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(l10n.telegramPlayLocal),
                                ),
                                OutlinedButton.icon(
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () => ref
                                            .read(playerProvider.notifier)
                                            .playAllShuffled(songs),
                                  icon: const Icon(Icons.shuffle_rounded),
                                  label: Text(l10n.shuffleAll),
                                ),
                                IconButton(
                                  tooltip: l10n.telegramSelect,
                                  onPressed: tracks.isEmpty
                                      ? null
                                      : () => controller.toggleSelection(
                                          tracks.first.audio.key,
                                        ),
                                  icon: const Icon(Icons.checklist_rounded),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: l10n.sortLabel,
                                  initialValue: state.sort,
                                  onSelected: controller.setSort,
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'newest',
                                      child: Text(l10n.telegramNewest),
                                    ),
                                    PopupMenuItem(
                                      value: 'oldest',
                                      child: Text(l10n.telegramOldest),
                                    ),
                                    PopupMenuItem(
                                      value: 'title',
                                      child: Text(l10n.telegramByTitle),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _query,
                              onChanged: controller.search,
                              decoration: InputDecoration(
                                hintText: l10n.telegramSearchMusic,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: IconButton(
                                  tooltip: l10n.cancel,
                                  onPressed: () {
                                    _query.clear();
                                    controller.search('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.telegramLoadedSearchHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (!widget.connected) Text(l10n.telegramOffline),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterHeader(
                        extent:
                            AppSpacing.iconHero +
                            (MediaQuery.textScalerOf(context).scale(
                                  Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.fontSize ??
                                      kDefaultFontSize,
                                ) -
                                (Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.fontSize ??
                                    kDefaultFontSize)),
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: AppSpacing.screenPadding,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: Text(l10n.telegramLocal),
                                  selected:
                                      state.localOnly && !state.activeOnly,
                                  onSelected: (_) =>
                                      controller.setLocalOnly(true),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ChoiceChip(
                                  label: Text(l10n.telegramAllAudio),
                                  selected:
                                      !state.localOnly && !state.activeOnly,
                                  onSelected: (_) =>
                                      controller.setLocalOnly(false),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ChoiceChip(
                                  label: Text(l10n.telegramDownloads),
                                  selected: state.activeOnly,
                                  onSelected: (_) => controller.setActiveOnly(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: TelegramDownloadDock()),
                    if (state.failure != null)
                      SliverToBoxAdapter(
                        child: TelegramErrorBanner(
                          failure: state.failure!,
                          onRetry: widget.connected
                              ? () => controller.refresh()
                              : null,
                        ),
                      ),
                    if (state.busy)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.allMd,
                          child: LinearProgressIndicator(),
                        ),
                      ),
                    if (tracks.isEmpty && !state.busy && state.failure == null)
                      SliverToBoxAdapter(
                        child: AppEmptyState(
                          icon: Icons.library_music_outlined,
                          title: state.query.isNotEmpty
                              ? l10n.noResultsTitle
                              : state.localOnly
                              ? l10n.telegramNoAudio
                              : l10n.telegramEmptyChat,
                          message: state.query.isNotEmpty
                              ? l10n.noResultsMessage
                              : state.localOnly
                              ? l10n.telegramNoAudioHint
                              : l10n.telegramLoadedSearchHint,
                        ),
                      ),
                    SliverList.builder(
                      itemCount: tracks.length,
                      itemBuilder: (_, index) => TelegramTrackTile(
                        key: ValueKey(tracks[index].audio.key),
                        track: tracks[index],
                        connected: widget.connected,
                      ),
                    ),
                    if (widget.connected && state.nextId != 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppSpacing.allMd,
                          child: OutlinedButton.icon(
                            onPressed: state.busy
                                ? null
                                : () => controller.refresh(more: true),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(l10n.telegramLoadMore),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                  ],
                ),
              ),
            ),
          ),
          if (state.selected.isNotEmpty)
            Flexible(
              child: TelegramSelectionOverlay(
                visible: true,
                child: _SelectionToolbar(chatId: id),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({required this.child, required this.extent});
  final Widget child;
  final double extent;
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => minExtent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant _FilterHeader oldDelegate) =>
      child != oldDelegate.child || extent != oldDelegate.extent;
}

class _SelectionToolbar extends ConsumerWidget {
  const _SelectionToolbar({required this.chatId});
  final int chatId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(telegramSelectionProvider(chatId));
    final selected = selection.$1;
    final total = selection.$2;
    final details = ref.watch(telegramSelectionDetailsProvider(chatId));
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: AppSpacing.allSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.telegramSelection(
                      selected.length,
                      total.readableFileSize,
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.cancel,
                  onPressed: ref
                      .read(telegramChatProvider(chatId).notifier)
                      .clearSelection,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l10n.telegramDownloadSelected),
                  onPressed: details.remoteCount == 0
                      ? null
                      : () async {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (dialog) => AlertDialog(
                              title: Text(l10n.telegramDownloadSelected),
                              content: Text(
                                l10n.telegramSelection(
                                  details.remoteCount,
                                  details.remoteBytes.readableFileSize,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialog, false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dialog, true),
                                  child: Text(l10n.telegramContinue),
                                ),
                              ],
                            ),
                          );
                          if (yes != true || !context.mounted) return;
                          final manager = ref.read(
                            telegramDownloadsProvider.notifier,
                          );
                          for (final track in selected) {
                            if (track.song == null &&
                                !manager.enqueue(track.audio)) {
                              showAppSnackBar(
                                context,
                                l10n.telegramQueueFull,
                                error: true,
                              );
                              break;
                            }
                          }
                          ref
                              .read(telegramChatProvider(chatId).notifier)
                              .clearSelection();
                        },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.queue_music_rounded),
                  label: Text(l10n.telegramQueueSelected),
                  onPressed: details.local.isEmpty
                      ? null
                      : () async {
                          final player = ref.read(playerProvider.notifier);
                          for (final track in selected) {
                            if (track.song != null) {
                              await player.addToQueue(track.song!);
                            }
                          }
                          if (context.mounted) {
                            ref
                                .read(telegramChatProvider(chatId).notifier)
                                .clearSelection();
                          }
                        },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(l10n.addToPlaylist),
                  onPressed: details.indexed.isEmpty
                      ? null
                      : () => showAddSongsToPlaylistSheet(
                          context,
                          details.indexed,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

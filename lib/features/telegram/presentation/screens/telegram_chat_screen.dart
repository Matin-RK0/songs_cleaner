import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../library/presentation/widgets/song_list_view.dart';
import '../../../player/application/providers/player_controller.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import '../widgets/telegram_feedback.dart';
import '../widgets/telegram_track_tile.dart';
import '../widgets/telegram_chat_avatar.dart';

class TelegramChatScreen extends ConsumerWidget {
  const TelegramChatScreen({super.key, required this.chatId});
  final int chatId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(
      telegramProvider.select((s) {
        for (final chat in s.chats) {
          if (chat.id == chatId) return chat;
        }
        return null;
      }),
    );
    final hasCurrent = ref.watch(playerProvider.select((s) => s.hasCurrent));
    final connected = ref.watch(
      telegramProvider.select((s) => s.auth == TelegramAuth.ready),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (chat != null) ...[
              TelegramChatAvatar(chat: chat, size: AppSpacing.avatarSize),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                chatId == 0
                    ? context.l10n.telegramFolders
                    : chat?.title ?? context.l10n.telegramTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (chatId != 0)
            IconButton(
              tooltip: connected
                  ? context.l10n.telegramSyncAudio
                  : context.l10n.telegramReconnect,
              onPressed: connected
                  ? () => ref
                        .read(telegramChatProvider(chatId).notifier)
                        .refresh()
                  : () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.telegramAuth),
              icon: Icon(
                connected ? Icons.refresh_rounded : Icons.link_rounded,
              ),
            ),
        ],
      ),
      body: chatId == 0
          ? const _TelegramFolderSongs()
          : _TelegramChatBody(chatId: chatId, connected: connected),
      bottomNavigationBar: hasCurrent
          ? const SafeArea(top: false, child: MiniPlayerBar())
          : null,
    );
  }
}

class _TelegramFolderSongs extends ConsumerWidget {
  const _TelegramFolderSongs();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(telegramUnassignedProvider);
    final current = ref.watch(playerProvider.select((s) => s.current?.id));
    return songs.isEmpty
        ? AppEmptyState(
            icon: Icons.folder_off_outlined,
            title: context.l10n.telegramNoAudio,
            message: context.l10n.telegramPrivacy,
          )
        : SongListView(
            songs: songs,
            currentSongId: current,
            onSongTap: (list, index) => ref
                .read(playerProvider.notifier)
                .playFromList(list, startIndex: index),
          );
  }
}

class _TelegramChatBody extends ConsumerWidget {
  const _TelegramChatBody({required this.chatId, required this.connected});
  final int chatId;
  final bool connected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(telegramChatProvider(chatId));
    final tracks = ref.watch(telegramChatTracksProvider(chatId));
    final songs = ref.watch(telegramChatSongsProvider(chatId));
    final controller = ref.read(telegramChatProvider(chatId).notifier);
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
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
                  if (ref.watch(telegramLocalMatchCountProvider(chatId)) >
                      0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.telegramLocalMatchesCount(
                        ref.watch(telegramLocalMatchCountProvider(chatId)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.telegramLocalMatchesHint),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.telegramLocal),
                        selected: state.localOnly,
                        onSelected: (_) => controller.setLocalOnly(true),
                      ),
                      ChoiceChip(
                        label: Text(l10n.telegramAllAudio),
                        selected: !state.localOnly,
                        onSelected: (_) => controller.setLocalOnly(false),
                      ),
                      if (songs.isNotEmpty)
                        FilledButton.tonalIcon(
                          onPressed: () => ref
                              .read(playerProvider.notifier)
                              .playFromList(songs, startIndex: 0),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.telegramPlayLocal),
                        ),
                    ],
                  ),
                  if (!connected)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(l10n.telegramOfflineHint),
                    ),
                ],
              ),
            ),
          ),
          if (state.failure != null)
            SliverToBoxAdapter(
              child: TelegramErrorBanner(
                failure: state.failure!,
                onRetry: connected ? () => controller.refresh() : null,
              ),
            ),
          if (state.busy)
            const SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.allMd,
                child: LinearProgressIndicator(),
              ),
            ),
          if (tracks.isEmpty && !state.busy)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.allLg,
                child: AppEmptyState(
                  icon: Icons.library_music_outlined,
                  title: state.localOnly
                      ? l10n.telegramNoAudio
                      : l10n.telegramEmptyChat,
                  message: state.localOnly ? l10n.telegramNoAudioHint : null,
                ),
              ),
            ),
          SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) => TelegramTrackTile(
              key: ValueKey(tracks[index].audio.key),
              track: tracks[index],
              connected: connected,
            ),
          ),
          if (connected && state.nextId != 0)
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
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

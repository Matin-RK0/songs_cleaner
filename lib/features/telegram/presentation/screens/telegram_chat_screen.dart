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
import '../widgets/telegram_chat_avatar.dart';
import '../widgets/telegram_chat_library.dart';
import '../widgets/telegram_download_sheet.dart';

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
              HeroMode(
                enabled: !MediaQuery.disableAnimationsOf(context),
                child: Hero(
                  tag: 'telegram-chat-${chat.id}',
                  child: TelegramChatAvatar(
                    chat: chat,
                    size: AppSpacing.avatarSize,
                  ),
                ),
              ),
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
          IconButton(
            tooltip: context.l10n.telegramDownloads,
            onPressed: () => showTelegramDownloads(context),
            icon: const Icon(Icons.downloading_rounded),
          ),
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
      body: TickerMode(
        enabled: ModalRoute.of(context)?.isCurrent != false,
        child: chatId == 0
            ? const _TelegramFolderSongs()
            : TelegramChatLibrary(chatId: chatId, connected: connected),
      ),
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
        ? SingleChildScrollView(
            child: AppEmptyState(
              icon: Icons.folder_off_outlined,
              title: context.l10n.emptyLibraryTitle,
              message: context.l10n.telegramFoldersHint,
            ),
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

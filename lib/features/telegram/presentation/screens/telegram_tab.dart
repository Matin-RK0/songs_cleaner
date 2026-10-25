import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import '../widgets/telegram_feedback.dart';
import '../widgets/telegram_overview_card.dart';

class TelegramTab extends ConsumerWidget {
  const TelegramTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(telegramProvider.select((e) => e.auth));
    final connected = auth == TelegramAuth.ready;
    return RefreshIndicator(
      onRefresh: () => ref.read(telegramProvider.notifier).refresh(),
      child: CustomScrollView(
        key: const PageStorageKey('telegram-chats'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: AppSpacing.allMd,
            sliver: SliverToBoxAdapter(
              child: TelegramOverviewCard(connected: connected),
            ),
          ),
          const SliverToBoxAdapter(child: _TelegramFoldersTile()),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.allMd,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.telegramChats,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (connected) ...[
                    IconButton(
                      tooltip: context.l10n.telegramRefresh,
                      onPressed: () =>
                          ref.read(telegramProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: context.l10n.telegramLogout,
                      onPressed: () => _disconnect(context, ref),
                      icon: const Icon(Icons.link_off_rounded),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: TextField(
                onChanged: ref.read(telegramProvider.notifier).search,
                decoration: InputDecoration(
                  hintText: context.l10n.telegramSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _TelegramStatus()),
          const _TelegramChatList(),
          if (connected)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.allMd,
                child: Consumer(
                  builder: (context, ref, _) {
                    final busy = ref.watch(
                      telegramProvider.select((e) => e.busy),
                    );
                    return OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => ref
                                .read(telegramProvider.notifier)
                                .refresh(more: true),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: Text(context.l10n.telegramLoadMore),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: MiniPlayerBar.height + AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.telegramLogoutTitle),
        content: Text(l10n.telegramLogoutHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.telegramLogout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(telegramProvider.notifier).logout();
    }
  }
}

class _TelegramFoldersTile extends ConsumerWidget {
  const _TelegramFoldersTile();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(telegramUnassignedProvider.select((e) => e.length));
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Card(
        child: ListTile(
          contentPadding: AppSpacing.allMd,
          leading: const Icon(Icons.folder_open_rounded),
          title: Text(context.l10n.telegramFolders),
          subtitle: Text(
            '${context.l10n.telegramFoldersHint}\n${context.l10n.telegramLocalCount(count)}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(RouteNames.telegramChat, arguments: 0),
        ),
      ),
    );
  }
}

class _TelegramStatus extends ConsumerWidget {
  const _TelegramStatus();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(telegramProvider.select((e) => e.busy));
    final failure = ref.watch(telegramProvider.select((e) => e.failure));
    return Column(
      children: [
        if (busy)
          const Padding(
            padding: AppSpacing.allMd,
            child: LinearProgressIndicator(),
          ),
        if (failure != null)
          TelegramErrorBanner(
            failure: failure,
            onRetry: () => ref.read(telegramProvider.notifier).refresh(),
          ),
      ],
    );
  }
}

class _TelegramChatList extends ConsumerWidget {
  const _TelegramChatList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(telegramVisibleChatsProvider);
    if (chats.isEmpty) {
      final query = ref.watch(telegramProvider.select((e) => e.query));
      return SliverToBoxAdapter(
        child: Padding(
          padding: AppSpacing.allLg,
          child: AppEmptyState(
            icon: Icons.forum_outlined,
            title: query.isEmpty
                ? context.l10n.telegramNoChats
                : context.l10n.telegramNoResults,
            message: context.l10n.telegramNoChatsHint,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: AppSpacing.allMd,
      sliver: SliverList.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final colors = Theme.of(context).colorScheme;
          final private = chat.kind == 'chatTypePrivate';
          return Padding(
            key: ValueKey(chat.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: colors.surfaceContainerLow,
              borderRadius: AppRadius.lg,
              child: ListTile(
                contentPadding: AppSpacing.hMdVSm,
                leading: CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  child: Icon(
                    private
                        ? Icons.person_outline_rounded
                        : Icons.forum_outlined,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  private
                      ? context.l10n.telegramConversation
                      : context.l10n.telegramChannelOrGroup,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(RouteNames.telegramChat, arguments: chat.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

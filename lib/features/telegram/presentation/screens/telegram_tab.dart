import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../player/presentation/widgets/mini_player_bar.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import '../widgets/telegram_feedback.dart';
import '../widgets/telegram_overview_card.dart';
import '../widgets/telegram_chat_tile.dart';
import '../widgets/telegram_download_sheet.dart';
import '../../application/telegram_preferences_controller.dart';

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
          const SliverToBoxAdapter(child: _TelegramChatSearch()),
          const SliverToBoxAdapter(child: _TelegramStatus()),
          const SliverToBoxAdapter(child: TelegramDownloadDock()),
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
          trailing: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
          ),
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
      final status = ref.watch(
        telegramProvider.select(
          (e) => (e.query, e.busy, e.failure, e.auth, e.chats.isEmpty),
        ),
      );
      final query = status.$1;
      if (status.$5 && (status.$2 || status.$3 != null)) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverToBoxAdapter(
        child: Padding(
          padding: AppSpacing.allLg,
          child: AppEmptyState(
            icon: Icons.forum_outlined,
            title: query.isEmpty
                ? context.l10n.telegramNoChats
                : context.l10n.telegramNoResults,
            message: query.isNotEmpty
                ? context.l10n.noResultsMessage
                : status.$4 == TelegramAuth.ready
                ? context.l10n.telegramNoChatsConnectedHint
                : context.l10n.telegramNoChatsHint,
            action: query.isEmpty
                ? null
                : TextButton(
                    onPressed: () =>
                        ref.read(telegramProvider.notifier).search(''),
                    child: Text(context.l10n.telegramClearSearch),
                  ),
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
          return Padding(
            key: ValueKey(chat.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TelegramChatEntry(
              chat: chat,
              onTap: () {
                final preferences = ref.read(
                  telegramPreferencesProvider.notifier,
                );
                Navigator.of(context)
                    .pushNamed(RouteNames.telegramChat, arguments: chat.id)
                    .then((_) {
                      if (context.mounted) preferences.remember(chat.id);
                    });
              },
            ),
          );
        },
      ),
    );
  }
}

class _TelegramChatSearch extends ConsumerStatefulWidget {
  const _TelegramChatSearch();

  @override
  ConsumerState<_TelegramChatSearch> createState() =>
      _TelegramChatSearchState();
}

class _TelegramChatSearchState extends ConsumerState<_TelegramChatSearch> {
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: ref.read(telegramProvider).query);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(telegramProvider.select((e) => e.query), (_, value) {
      if (_query.text != value) {
        _query.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    });
    return Padding(
      padding: AppSpacing.screenPadding,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _query,
        builder: (context, value, _) => TextField(
          controller: _query,
          onChanged: ref.read(telegramProvider.notifier).search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.telegramSearch,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.telegramClearSearch,
                    onPressed: () {
                      _query.clear();
                      ref.read(telegramProvider.notifier).search('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
    );
  }
}

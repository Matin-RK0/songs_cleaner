import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import 'telegram_cache_controls.dart';

enum _TabAction { refresh, cache, disconnect }

class TelegramTabActions extends ConsumerWidget {
  const TelegramTabActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(
      telegramProvider.select((state) => state.auth == TelegramAuth.ready),
    );
    final busy = ref.watch(
      telegramProvider.select((state) => state.busy || state.clearingCache),
    );
    final l10n = context.l10n;
    return PopupMenuButton<_TabAction>(
      tooltip: l10n.moreActions,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (action) {
        switch (action) {
          case _TabAction.refresh:
            ref.read(telegramProvider.notifier).refresh();
          case _TabAction.cache:
            showTelegramCacheDialog(context, ref);
          case _TabAction.disconnect:
            _disconnect(context, ref);
        }
      },
      itemBuilder: (_) => [
        if (connected)
          PopupMenuItem(
            value: _TabAction.refresh,
            enabled: !busy,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh_rounded),
              title: Text(l10n.telegramRefresh),
            ),
          ),
        PopupMenuItem(
          value: _TabAction.cache,
          enabled: !busy,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.telegramClearCache),
          ),
        ),
        if (connected) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _TabAction.disconnect,
            enabled: !busy,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_off_rounded),
              title: Text(l10n.telegramLogout),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.telegramLogoutTitle),
        content: Text(l10n.telegramLogoutHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
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

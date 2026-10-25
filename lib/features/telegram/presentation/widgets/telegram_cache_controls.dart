import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_sheet_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';

class TelegramCacheTile extends ConsumerWidget {
  const TelegramCacheTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(telegramProvider.select((state) => state.busy));
    final clearing = ref.watch(
      telegramProvider.select((state) => state.clearingCache),
    );
    return ListTile(
      leading: Icon(
        Icons.cleaning_services_outlined,
        color: context.colors.primary,
      ),
      title: Text(context.l10n.telegramClearCache),
      subtitle: Semantics(
        liveRegion: clearing,
        child: Text(
          clearing
              ? context.l10n.telegramClearingCache
              : context.l10n.telegramClearCacheSubtitle,
        ),
      ),
      trailing: clearing
          ? const _CacheProgress()
          : Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppSpacing.md,
              color: context.colors.textLow,
            ),
      enabled: !busy,
      onTap: () => showTelegramCacheDialog(context, ref),
    );
  }
}

class TelegramCacheButton extends ConsumerWidget {
  const TelegramCacheButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(telegramProvider.select((state) => state.busy));
    final clearing = ref.watch(
      telegramProvider.select((state) => state.clearingCache),
    );
    return IconButton(
      tooltip: context.l10n.telegramClearCache,
      icon: clearing
          ? const _CacheProgress()
          : const Icon(Icons.cleaning_services_outlined),
      onPressed: busy ? null : () => showTelegramCacheDialog(context, ref),
    );
  }
}

class _CacheProgress extends StatelessWidget {
  const _CacheProgress();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSpacing.lg,
    child: CircularProgressIndicator(
      strokeWidth: AppSpacing.progressStroke,
      semanticsLabel: context.l10n.telegramClearingCache,
    ),
  );
}

Future<void> showTelegramCacheDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final canSignOut = ref.read(telegramProvider).auth == TelegramAuth.ready;
  var signOut = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.telegramClearCache),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.telegramClearCacheHint),
            if (canSignOut) ...[
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: signOut,
                title: Text(l10n.telegramClearCacheSignOut),
                subtitle: Text(l10n.telegramClearCacheSignOutHint),
                onChanged: (value) => setState(() => signOut = value ?? false),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppSheetActions(
              primaryLabel: l10n.telegramClearCache,
              onPrimary: () => Navigator.pop(dialogContext, true),
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogContext, false),
              destructive: true,
            ),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final success = await ref
      .read(telegramProvider.notifier)
      .clearCache(signOut: signOut);
  if (!context.mounted) return;
  showAppSnackBar(
    context,
    success ? l10n.telegramCacheCleared : l10n.telegramCacheClearFailed,
    error: !success,
  );
}

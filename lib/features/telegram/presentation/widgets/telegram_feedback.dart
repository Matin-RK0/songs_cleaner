import 'package:flutter/material.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/telegram_models.dart';

String telegramFailureText(BuildContext context, TelegramFailure failure) {
  final l10n = context.l10n;
  return switch (failure) {
    TelegramFailure.network => l10n.telegramErrorNetwork,
    TelegramFailure.phone => l10n.telegramErrorPhone,
    TelegramFailure.code => l10n.telegramErrorCode,
    TelegramFailure.password => l10n.telegramErrorPassword,
    TelegramFailure.flood => l10n.telegramErrorFlood,
    TelegramFailure.storage => l10n.telegramErrorStorage,
    TelegramFailure.generic => l10n.telegramErrorGeneric,
  };
}

class TelegramErrorBanner extends StatelessWidget {
  const TelegramErrorBanner({super.key, required this.failure, this.onRetry});
  final TelegramFailure failure;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.allMd,
    child: Semantics(
      liveRegion: true,
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        borderRadius: AppRadius.lg,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(telegramFailureText(context, failure))),
              if (onRetry != null)
                IconButton(
                  tooltip: context.l10n.retry,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

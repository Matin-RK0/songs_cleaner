import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/telegram_entrance.dart';

class TelegramOverviewCard extends StatelessWidget {
  const TelegramOverviewCard({super.key, required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xl,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.primaryContainer, colors.surfaceContainerHigh],
          ),
        ),
        child: Padding(
          padding: AppSpacing.allLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TelegramEntrance(
                    child: Icon(
                      Icons.telegram_rounded,
                      size: AppSpacing.iconHero,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      connected ? l10n.telegramConnected : l10n.telegramOffline,
                      style: text.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    connected
                        ? Icons.check_circle_outline_rounded
                        : Icons.offline_pin_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ],
              ),
              if (!connected) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.telegramHeadline,
                  style: text.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  connected
                      ? l10n.telegramDescription
                      : l10n.telegramOfflineHint,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
              if (!connected) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.telegramAuth),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(l10n.telegramConnect),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/telegram_entrance.dart';
import '../../domain/telegram_models.dart';

class TelegramOverviewCard extends StatelessWidget {
  const TelegramOverviewCard({
    super.key,
    required this.connected,
    this.connection = TelegramConnection.unknown,
  });
  final bool connected;
  final TelegramConnection connection;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final reconnecting = connected && connection.unavailable;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xl,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.surfaceContainerLow, colors.surfaceContainer],
          ),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: AppSpacing.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TelegramEntrance(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: AppRadius.lg,
                      ),
                      child: Padding(
                        padding: AppSpacing.allSm,
                        child: Icon(
                          Icons.telegram_rounded,
                          size: AppSpacing.xl,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.telegramTitle, style: text.titleLarge),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          reconnecting
                              ? l10n.telegramReconnecting
                              : connected
                              ? l10n.telegramConnected
                              : l10n.telegramOffline,
                          style: text.labelMedium?.copyWith(
                            color: reconnecting || !connected
                                ? colors.onSurfaceVariant
                                : colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    reconnecting
                        ? Icons.sync_rounded
                        : connected
                        ? Icons.check_circle_outline_rounded
                        : Icons.offline_pin_outlined,
                    color: reconnecting || !connected
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                ],
              ),
              if (connected) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.telegramDescription,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (!connected) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.telegramHeadline, style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.telegramOfflineHint,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (!connected) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.telegramAuth),
                    icon: const Icon(Icons.link_rounded),
                    label: Text(l10n.telegramConnect),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

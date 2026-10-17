import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/file_size_format.dart';
import '../widgets/insight_metric_card.dart';
import '../../application/providers/library_insights_provider.dart';

class LibraryInsightsScreen extends ConsumerWidget {
  const LibraryInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(libraryInsightsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.libraryInsightsTitle)),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              color: context.colors.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 40,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    insights.totalBytes.readableFileSize,
                    style: AppTypography.playerTitle.copyWith(
                      color: context.colors.textHigh,
                    ),
                  ),
                  Text(
                    context.l10n.librarySummary(
                      insights.totalSongs,
                      insights.totalDuration.mmss,
                    ),
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  InsightMetricCard(
                    width: cardWidth,
                    icon: Icons.edit_note_rounded,
                    value: '${insights.missingMetadataCount}',
                    label: context.l10n.missingMetadataMetric,
                  ),
                  InsightMetricCard(
                    width: cardWidth,
                    icon: Icons.timer_outlined,
                    value: '${insights.shortTrackCount}',
                    label: context.l10n.shortTracksMetric,
                  ),
                  InsightMetricCard(
                    width: cardWidth,
                    icon: Icons.high_quality_rounded,
                    value: '${insights.losslessCount}',
                    label: context.l10n.losslessMetric,
                  ),
                  InsightMetricCard(
                    width: cardWidth,
                    icon: Icons.sd_storage_outlined,
                    value: '${insights.largeFileCount}',
                    label: context.l10n.largeFilesMetric,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.duplicatesTitle,
            style: AppTypography.sectionTitle.copyWith(
              color: context.colors.textHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.copy_all_rounded,
                color: context.colors.accent,
              ),
              title: Text(
                context.l10n.potentialDuplicatesCount(
                  insights.duplicateFileCount,
                ),
              ),
              subtitle: Text(
                context.l10n.recoverableSpace(
                  insights.recoverableBytes.readableFileSize,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.duplicateScanner),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.formatsTitle,
            style: AppTypography.sectionTitle.copyWith(
              color: context.colors.textHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: context.colors.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
            ),
            child: Column(
              children: [
                for (final entry in insights.formatCounts.entries)
                  ListTile(
                    title: Text(entry.key.toUpperCase()),
                    subtitle: Text(context.l10n.songCountLabel(entry.value)),
                    trailing: Text(
                      (insights.formatBytes[entry.key] ?? 0).readableFileSize,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/telegram_download_controller.dart';
import '../../application/telegram_download_sections_provider.dart';
import '../../application/telegram_controller.dart';
import '../../application/telegram_preferences_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../domain/telegram_download.dart';
import '../../domain/telegram_download_group.dart';
import '../../domain/telegram_models.dart';
import '../providers/download_labels_provider.dart';
import 'telegram_download_control.dart';
import 'telegram_feedback.dart';
import 'telegram_section_header.dart';

Future<void> showTelegramDownloads(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: RouteNames.telegramDownloads),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const SafeArea(top: false, child: TelegramDownloadsView()),
  );
}

class TelegramDownloadDock extends ConsumerStatefulWidget {
  const TelegramDownloadDock({super.key});
  @override
  ConsumerState<TelegramDownloadDock> createState() =>
      _TelegramDownloadDockState();
}

class _TelegramDownloadDockState extends ConsumerState<TelegramDownloadDock> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.l10n.localeName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(telegramDownloadsProvider.notifier).language(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(telegramDownloadSummaryProvider);
    return ListTile(
      leading: const Icon(Icons.downloading_rounded),
      title: Text(context.l10n.telegramDownloads),
      subtitle: Text(
        summary == (0, 0, 0, 0)
            ? context.l10n.telegramNoActiveDownloads
            : context.l10n.telegramDownloadsOverview(
                summary.$1,
                summary.$2,
                summary.$3,
                summary.$4,
              ),
      ),
      trailing: const Icon(Icons.expand_less_rounded),
      onTap: () => showTelegramDownloads(context),
    );
  }
}

class TelegramDownloadsView extends ConsumerWidget {
  const TelegramDownloadsView({super.key, this.fill = false});
  final bool fill;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(telegramDownloadSectionsProvider);
    final l10n = context.l10n;
    return SizedBox(
      height: fill
          ? double.infinity
          : MediaQuery.sizeOf(context).height * AppSpacing.sheetHeightFactor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _DownloadHeader(showTitle: !fill)),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(l10n.telegramNoDownloads)),
                ),
              for (final section in sections) ...[
                SliverToBoxAdapter(
                  child: TelegramSectionHeader(
                    title: switch (section.group) {
                      TelegramDownloadGroup.active =>
                        l10n.telegramDownloadsActiveGroup,
                      TelegramDownloadGroup.needsAttention =>
                        l10n.telegramDownloadsAttentionGroup,
                      TelegramDownloadGroup.finished =>
                        l10n.telegramDownloadsFinishedGroup,
                    },
                    count: section.ids.length,
                    icon: switch (section.group) {
                      TelegramDownloadGroup.active => Icons.downloading_rounded,
                      TelegramDownloadGroup.needsAttention =>
                        Icons.pending_actions_rounded,
                      TelegramDownloadGroup.finished => Icons.task_alt_rounded,
                    },
                  ),
                ),
                SliverList.builder(
                  itemCount: section.ids.length,
                  itemBuilder: (_, index) => _DownloadRow(
                    key: ValueKey(section.ids[index]),
                    id: section.ids[index],
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: AppSpacing.allMd,
                    child: Text(
                      l10n.telegramDownloadLocation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadHeader extends ConsumerWidget {
  const _DownloadHeader({required this.showTitle});
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final summary = ref.watch(telegramDownloadSummaryProvider);
    final actions = ref.watch(telegramDownloadBulkActionsProvider);
    final manager = ref.read(telegramDownloadsProvider.notifier);
    return Padding(
      padding: AppSpacing.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: showTitle,
                  child: Text(
                    showTitle
                        ? l10n.telegramDownloads
                        : l10n.telegramDownloadsOverview(
                            summary.$1,
                            summary.$2,
                            summary.$3,
                            summary.$4,
                          ),
                    style: showTitle ? text.titleLarge : text.bodyMedium,
                  ),
                ),
              ),
              PopupMenuButton<int>(
                tooltip: l10n.telegramDownloadSettings,
                icon: const Icon(Icons.tune_rounded),
                initialValue:
                    (ref.watch(
                                  telegramPreferencesProvider.select(
                                    (p) => p['parallel'],
                                  ),
                                )
                                as int? ??
                            2)
                        .clamp(1, 3),
                itemBuilder: (_) => [
                  for (var count = 1; count <= 3; count++)
                    PopupMenuItem(
                      value: count,
                      child: Text(l10n.telegramConcurrency(count)),
                    ),
                ],
                onSelected: ref
                    .read(telegramPreferencesProvider.notifier)
                    .parallel,
              ),
            ],
          ),
          if (showTitle)
            Text(
              l10n.telegramDownloadsOverview(
                summary.$1,
                summary.$2,
                summary.$3,
                summary.$4,
              ),
              style: text.bodyMedium,
            ),
          const SizedBox(height: AppSpacing.sm),
          const _DownloadConnectionStatus(),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: actions.pause ? manager.pauseAll : null,
                child: Text(l10n.telegramPauseAll),
              ),
              TextButton(
                onPressed: actions.resume ? manager.resumeAll : null,
                child: Text(l10n.telegramResumeAll),
              ),
              TextButton(
                onPressed: actions.clear ? manager.clearFinished : null,
                child: Text(l10n.telegramClearFinished),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadConnectionStatus extends ConsumerWidget {
  const _DownloadConnectionStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      telegramDownloadsProvider.select(
        (jobs) => jobs.values.any(
          (job) => job.unfinished || job.phase == TelegramDownloadPhase.failed,
        ),
      ),
    );
    final connection = ref.watch(
      telegramProvider.select(
        (state) =>
            (state.auth == TelegramAuth.ready, state.connection.unavailable),
      ),
    );
    if (!pending || connection.$1 && !connection.$2) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.l10n.telegramDownloadsWaitingForConnection,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextButton.icon(
            onPressed: connection.$1
                ? () => ref.read(telegramProvider.notifier).refresh()
                : () =>
                      Navigator.of(context).pushNamed(RouteNames.telegramAuth),
            icon: const Icon(Icons.link_rounded),
            label: Text(context.l10n.telegramReconnect),
          ),
        ],
      ),
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(telegramDownloadsProvider.select((jobs) => jobs[id]));
    if (job == null) return const SizedBox.shrink();
    final labels = ref.watch(
      telegramDownloadLabelsProvider((id, context.l10n.localeName)),
    );
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: AppSpacing.hMdVSm,
            title: Text(
              job.audio.title.isEmpty ? job.audio.fileName : job.audio.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(labels.$1, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '\u2068${labels.$2}\u2069',
                  style: theme.textTheme.bodySmall,
                ),
                if (labels.$3.isNotEmpty)
                  Text(
                    '\u2068${labels.$3}\u2069',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: TelegramDownloadControl(audio: job.audio, enabled: true),
          ),
          TelegramDownloadLine(id: id),
          if (job.failure != null)
            Padding(
              padding: AppSpacing.allSm,
              child: Text(
                telegramFailureText(context, job.failure!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (job.phase == TelegramDownloadPhase.receiving ||
              job.phase == TelegramDownloadPhase.paused)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(telegramDownloadsProvider.notifier)
                    .pause(id, discard: true),
                icon: const Icon(Icons.close_rounded),
                label: Text(context.l10n.cancel),
              ),
            ),
          const Divider(height: AppSpacing.progressStroke),
        ],
      ),
    );
  }
}

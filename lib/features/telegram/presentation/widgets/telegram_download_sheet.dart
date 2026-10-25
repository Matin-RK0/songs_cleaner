import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/telegram_download_controller.dart';
import '../../application/telegram_preferences_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../domain/telegram_download.dart';
import '../providers/download_labels_provider.dart';
import 'telegram_download_control.dart';
import 'telegram_feedback.dart';

Future<void> showTelegramDownloads(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: RouteNames.telegramDownloads),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const TelegramDownloadsView(),
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
    final ids = ref.watch(telegramDownloadIdsProvider);
    final manager = ref.read(telegramDownloadsProvider.notifier);
    final l10n = context.l10n;
    return SizedBox(
      height: fill
          ? double.infinity
          : MediaQuery.sizeOf(context).height * AppSpacing.sheetHeightFactor,
      child: Column(
        children: [
          RepaintBoundary(
            child: Padding(
              padding: AppSpacing.allMd,
              child: Column(
                children: [
                  Text(
                    l10n.telegramDownloads,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.telegramDownloadLocation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value:
                        (ref.watch(telegramPreferencesProvider)['parallel']
                                    as int? ??
                                2)
                            .clamp(1, 3),
                    items: [
                      for (var count = 1; count <= 3; count++)
                        DropdownMenuItem(
                          value: count,
                          child: Text(
                            l10n.telegramConcurrency(count),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(telegramPreferencesProvider.notifier)
                            .parallel(value);
                      }
                    },
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      TextButton(
                        onPressed: manager.pauseAll,
                        child: Text(l10n.telegramPauseAll),
                      ),
                      TextButton(
                        onPressed: manager.resumeAll,
                        child: Text(l10n.telegramResumeAll),
                      ),
                      IconButton(
                        tooltip: l10n.telegramClearFinished,
                        onPressed: manager.clearFinished,
                        icon: const Icon(Icons.cleaning_services_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              child: ids.isEmpty
                  ? Center(child: Text(l10n.telegramNoDownloads))
                  : ListView.builder(
                      itemCount: ids.length,
                      itemBuilder: (_, index) => _DownloadRow(id: ids[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.id});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(telegramDownloadsProvider.select((jobs) => jobs[id]));
    if (job == null) return const SizedBox.shrink();
    final labels = ref.watch(
      telegramDownloadLabelsProvider((id, context.l10n.localeName)),
    );
    return Padding(
      padding: AppSpacing.allSm,
      child: Column(
        children: [
          ListTile(
            title: Text(
              job.audio.title.isEmpty ? job.audio.fileName : job.audio.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${labels.$1}\n${labels.$2}${labels.$3.isEmpty ? '' : '\n${labels.$3}'}',
            ),
            trailing: TelegramDownloadControl(audio: job.audio, enabled: true),
          ),
          TelegramDownloadLine(id: id),
          if (job.failure != null)
            Padding(
              padding: AppSpacing.allSm,
              child: Text(
                telegramFailureText(context, job.failure!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (job.unfinished && job.phase != TelegramDownloadPhase.saving)
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
        ],
      ),
    );
  }
}

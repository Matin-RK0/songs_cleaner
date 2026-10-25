import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../application/telegram_download_controller.dart';
import '../../domain/telegram_download.dart';
import '../../domain/telegram_models.dart';
import '../providers/download_labels_provider.dart';

class TelegramDownloadControl extends ConsumerWidget {
  const TelegramDownloadControl({
    super.key,
    required this.audio,
    required this.enabled,
    this.allowRedownload = false,
  });
  final TelegramAudio audio;
  final bool enabled;
  final bool allowRedownload;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(
      telegramDownloadsProvider.select((jobs) => jobs[audio.fileId]),
    );
    final manager = ref.read(telegramDownloadsProvider.notifier);
    final l10n = context.l10n;
    final phase =
        allowRedownload && job?.phase == TelegramDownloadPhase.completed
        ? null
        : job?.phase;
    final busy =
        phase == TelegramDownloadPhase.receiving ||
        phase == TelegramDownloadPhase.saving;
    final paused =
        phase == TelegramDownloadPhase.paused ||
        phase == TelegramDownloadPhase.failed ||
        phase == TelegramDownloadPhase.canceled;
    final icon = phase == TelegramDownloadPhase.completed
        ? Icons.check_rounded
        : phase == TelegramDownloadPhase.receiving
        ? Icons.pause_rounded
        : phase == TelegramDownloadPhase.saving
        ? Icons.save_alt_rounded
        : phase == TelegramDownloadPhase.queued
        ? Icons.close_rounded
        : paused
        ? Icons.play_arrow_rounded
        : Icons.download_rounded;
    return RepaintBoundary(
      child: TickerMode(
        enabled:
            !MediaQuery.disableAnimationsOf(context) &&
            ModalRoute.of(context)?.isCurrent != false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (busy)
              SizedBox.square(
                dimension: AppSpacing.avatarSize - AppSpacing.sm,
                child: CircularProgressIndicator(
                  value: phase == TelegramDownloadPhase.saving
                      ? null
                      : job!.fraction,
                  strokeWidth: AppSpacing.progressStroke,
                ),
              ),
            IconButton(
              tooltip: phase == TelegramDownloadPhase.completed
                  ? l10n.telegramCompleted
                  : busy
                  ? phase == TelegramDownloadPhase.saving
                        ? l10n.telegramSaving
                        : l10n.telegramPause
                  : phase == TelegramDownloadPhase.failed
                  ? l10n.retry
                  : paused
                  ? l10n.telegramResume
                  : phase == TelegramDownloadPhase.queued
                  ? l10n.cancel
                  : l10n.telegramDownload,
              onPressed:
                  phase == TelegramDownloadPhase.saving ||
                      phase == TelegramDownloadPhase.completed
                  ? null
                  : busy
                  ? () => manager.pause(audio.fileId)
                  : phase == TelegramDownloadPhase.queued
                  ? () => manager.pause(audio.fileId, discard: true)
                  : !enabled
                  ? null
                  : () {
                      if (paused) {
                        manager.resume(audio.fileId);
                      } else if (!manager.enqueue(audio)) {
                        showAppSnackBar(
                          context,
                          l10n.telegramQueueFull,
                          error: true,
                        );
                      }
                    },
              icon: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.fast,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(icon, key: ValueKey(icon)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelegramDownloadSubtitle extends ConsumerWidget {
  const TelegramDownloadSubtitle({
    super.key,
    required this.audio,
    required this.fallback,
    this.hideCompleted = false,
  });
  final TelegramAudio audio;
  final String fallback;
  final bool hideCompleted;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(
      telegramDownloadLabelsProvider((audio.fileId, context.l10n.localeName)),
    );
    final completed = ref.watch(
      telegramDownloadsProvider.select(
        (jobs) => jobs[audio.fileId]?.phase == TelegramDownloadPhase.completed,
      ),
    );
    return Text(
      labels.$1.isEmpty || hideCompleted && completed
          ? fallback
          : '${labels.$1} · ${labels.$2}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TelegramDownloadLine extends ConsumerWidget {
  const TelegramDownloadLine({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(telegramDownloadsProvider.select((jobs) => jobs[id]));
    if (job == null || !job.active) return const SizedBox.shrink();
    return TickerMode(
      enabled:
          !MediaQuery.disableAnimationsOf(context) &&
          ModalRoute.of(context)?.isCurrent != false,
      child: LinearProgressIndicator(
        value: job.phase == TelegramDownloadPhase.saving ? null : job.fraction,
        minHeight: AppSpacing.progressStroke,
      ),
    );
  }
}

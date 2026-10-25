import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/utils/file_size_format.dart';
import '../../application/telegram_download_controller.dart';
import '../../domain/telegram_download.dart';

final telegramDownloadLabelsProvider = Provider.autoDispose
    .family<(String, String, String), (int, String)>((ref, key) {
      final job = ref.watch(
        telegramDownloadsProvider.select((jobs) => jobs[key.$1]),
      );
      if (job == null) return ('', '', '');
      final l10n = lookupAppLocalizations(Locale(key.$2));
      final label = switch (job.phase) {
        TelegramDownloadPhase.queued => l10n.telegramQueued,
        TelegramDownloadPhase.receiving =>
          job.fraction == null
              ? l10n.telegramReceiving
              : l10n.telegramPercent((job.fraction! * 100).round()),
        TelegramDownloadPhase.saving => l10n.telegramSaving,
        TelegramDownloadPhase.paused => l10n.telegramPaused,
        TelegramDownloadPhase.completed => l10n.telegramCompleted,
        TelegramDownloadPhase.failed => l10n.telegramErrorGeneric,
        TelegramDownloadPhase.canceled => l10n.telegramCanceled,
      };
      final bytes = job.total > 0
          ? l10n.telegramTransferBytes(
              job.received.readableFileSize,
              job.total.readableFileSize,
            )
          : job.received.readableFileSize;
      final eta = job.remainingSeconds;
      final speed = eta != null && job.phase == TelegramDownloadPhase.receiving
          ? l10n.telegramTransferSpeed(
              job.bytesPerSecond.round().readableFileSize,
              eta,
            )
          : '';
      return (label, bytes, speed);
    });

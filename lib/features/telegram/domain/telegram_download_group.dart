import 'telegram_download.dart';

enum TelegramDownloadGroup {
  active,
  needsAttention,
  finished;

  static TelegramDownloadGroup fromPhase(TelegramDownloadPhase phase) =>
      switch (phase) {
        TelegramDownloadPhase.queued ||
        TelegramDownloadPhase.receiving ||
        TelegramDownloadPhase.saving => active,
        TelegramDownloadPhase.paused ||
        TelegramDownloadPhase.failed => needsAttention,
        TelegramDownloadPhase.completed ||
        TelegramDownloadPhase.canceled => finished,
      };
}

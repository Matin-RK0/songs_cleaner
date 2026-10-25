import 'telegram_models.dart';

enum TelegramDownloadPhase {
  queued,
  receiving,
  saving,
  paused,
  completed,
  failed,
  canceled,
}

class TelegramTransferProgress {
  const TelegramTransferProgress({
    this.received = 0,
    this.total = 0,
    this.saving = false,
  });
  final int received;
  final int total;
  final bool saving;
}

class TelegramTransferInterrupted implements Exception {
  const TelegramTransferInterrupted();
}

class TelegramDownload {
  const TelegramDownload({
    required this.audio,
    this.phase = TelegramDownloadPhase.queued,
    this.received = 0,
    this.total = 0,
    this.bytesPerSecond = 0,
    this.path = '',
    this.failure,
    this.playWhenReady = false,
  });
  final TelegramAudio audio;
  final TelegramDownloadPhase phase;
  final int received;
  final int total;
  final double bytesPerSecond;
  final String path;
  final TelegramFailure? failure;
  final bool playWhenReady;
  bool get active =>
      phase == TelegramDownloadPhase.receiving ||
      phase == TelegramDownloadPhase.saving;
  bool get unfinished =>
      active ||
      phase == TelegramDownloadPhase.queued ||
      phase == TelegramDownloadPhase.paused;
  double? get fraction => total > 0 ? (received / total).clamp(0.0, 1.0) : null;
  int? get remainingSeconds => bytesPerSecond >= 1 && total > received
      ? ((total - received) / bytesPerSecond).ceil()
      : null;
  TelegramDownload copyWith({
    TelegramDownloadPhase? phase,
    int? received,
    int? total,
    double? bytesPerSecond,
    String? path,
    TelegramFailure? failure,
    bool? playWhenReady,
  }) => TelegramDownload(
    audio: audio,
    phase: phase ?? this.phase,
    received: received ?? this.received,
    total: total ?? this.total,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
    path: path ?? this.path,
    failure: failure,
    playWhenReady: playWhenReady ?? this.playWhenReady,
  );
}

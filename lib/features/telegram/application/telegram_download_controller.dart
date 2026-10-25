import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/domain/entities/song.dart';
import '../../player/application/providers/player_controller.dart';
import '../domain/telegram_download.dart';
import '../domain/telegram_models.dart';
import 'telegram_controller.dart';
import 'telegram_preferences_controller.dart';
import '../../library/application/providers/library_providers.dart';
import '../infrastructure/telegram_download_activity.dart';
import '../infrastructure/telegram_diagnostics.dart';

final telegramDownloadActivityProvider = Provider<TelegramDownloadActivity>(
  (ref) => TelegramDownloadActivity(),
);

final telegramDownloadPlayerProvider = Provider<Future<void> Function(Song)>(
  (ref) => (song) {
    var resolved = song;
    for (final local in ref.read(allSongsProvider)) {
      if (local.path == song.path) {
        resolved = local;
        break;
      }
    }
    return ref.read(playerProvider.notifier).playFromList([
      resolved,
    ], startIndex: 0);
  },
);

final telegramDownloadsProvider =
    NotifierProvider<TelegramDownloadController, Map<int, TelegramDownload>>(
      TelegramDownloadController.new,
    );

/// Committed public files are authoritative even while a metadata update or
/// MediaStore library scan is still pending.
final telegramPublishedPathsProvider = Provider<Map<int, String>>((ref) {
  ref.watch(
    telegramDownloadsProvider.select(
      (jobs) => Object.hashAll(
        jobs.values
            .where((job) => job.phase == TelegramDownloadPhase.completed)
            .map((job) => Object.hash(job.audio.fileId, job.path)),
      ),
    ),
  );
  return Map.unmodifiable({
    for (final job in ref.read(telegramDownloadsProvider).values)
      if (job.phase == TelegramDownloadPhase.completed && job.path.isNotEmpty)
        job.audio.fileId: job.path,
  });
});

// Stable summaries prevent every progress packet rebuilding the chat list.
final telegramDownloadSummaryProvider =
    Provider<(int active, int queued, int paused, int failed)>((ref) {
      final jobs = ref.watch(telegramDownloadsProvider);
      return (
        jobs.values.where((e) => e.active).length,
        jobs.values
            .where((e) => e.phase == TelegramDownloadPhase.queued)
            .length,
        jobs.values
            .where((e) => e.phase == TelegramDownloadPhase.paused)
            .length,
        jobs.values
            .where((e) => e.phase == TelegramDownloadPhase.failed)
            .length,
      );
    });
final telegramDownloadIdsProvider = Provider<List<int>>((ref) {
  ref.watch(
    telegramDownloadsProvider.select((jobs) => Object.hashAll(jobs.keys)),
  );
  return ref.read(telegramDownloadsProvider).keys.toList();
});

final telegramDownloadBulkActionsProvider =
    Provider<({bool pause, bool resume, bool clear})>((ref) {
      final jobs = ref.watch(telegramDownloadsProvider).values;
      return (
        pause: jobs.any(
          (job) =>
              job.phase == TelegramDownloadPhase.receiving ||
              job.phase == TelegramDownloadPhase.queued,
        ),
        resume: jobs.any(
          (job) =>
              job.phase == TelegramDownloadPhase.paused ||
              job.phase == TelegramDownloadPhase.failed,
        ),
        clear: jobs.any(_canClearDownload),
      );
    });

bool _canClearDownload(TelegramDownload job) =>
    job.phase == TelegramDownloadPhase.completed ||
    job.phase == TelegramDownloadPhase.canceled;

class TelegramDownloadController extends Notifier<Map<int, TelegramDownload>> {
  final _running = <int>{};
  final _stopping = <int>{};
  final _generation = <int, int>{};
  final _pendingProgress = <int, TelegramTransferProgress>{};
  final _samples = <int, (DateTime, int)>{};
  final _finishes = <int, Completer<void>>{};
  Timer? _flush;
  Timer? _heartbeat;
  bool _restoring = true;
  bool _pausingAll = false;
  bool _closing = false;
  (int, int)? _activitySummary;
  String? _language;
  Future<void> _persisting = Future.value();
  static const parallel = 2;
  int _limit = parallel;
  static const maxQueue = 200;

  @override
  Map<int, TelegramDownload> build() {
    final activity = ref.read(telegramDownloadActivityProvider);
    _limit =
        (ref.read(telegramPreferencesProvider)['parallel'] as int? ?? parallel)
            .clamp(1, 3);
    ref.listen(
      telegramPreferencesProvider.select((value) => value['parallel']),
      (_, value) {
        _limit = (value as int? ?? parallel).clamp(1, 3);
        _pump();
      },
    );
    ref.listen(telegramProvider.select((s) => s.auth), (_, auth) {
      if (auth == TelegramAuth.ready) _pump();
      if (auth == TelegramAuth.disconnected) unawaited(pauseAll());
    });
    ref.onDispose(() {
      _flush?.cancel();
      _heartbeat?.cancel();
      for (final completion in _finishes.values) {
        if (!completion.isCompleted) completion.complete();
      }
      unawaited(activity.update(0, 0));
    });
    Future.microtask(_restore);
    return const {};
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(telegramRepositoryProvider).savedTransfers();
      if (!ref.mounted) return;
      state = {
        for (final audio in saved.take(maxQueue))
          audio.fileId: TelegramDownload(
            audio: audio,
            phase: TelegramDownloadPhase.paused,
          ),
        ...state,
      };
    } catch (_) {
      /* A corrupt optional queue must not block the music library. */
    } finally {
      _restoring = false;
      if (ref.mounted) _pump();
    }
  }

  bool enqueue(TelegramAudio audio, {bool play = false}) {
    if (_closing) return false;
    final previous = state[audio.fileId];
    if (previous?.unfinished == true) return true;
    if (state.values.where((e) => e.unfinished).length >= maxQueue) {
      return false;
    }
    final next = Map<int, TelegramDownload>.of(state);
    final terminal = next.entries
        .where((e) => !e.value.unfinished)
        .map((e) => e.key)
        .toList();
    for (final id in terminal.take(
      (terminal.length - 39).clamp(0, terminal.length),
    )) {
      next.remove(id);
      if (!_running.contains(id)) _generation.remove(id);
    }
    next[audio.fileId] = TelegramDownload(
      audio: audio,
      total: audio.size,
      playWhenReady: play,
    );
    _finishes[audio.fileId] = Completer<void>();
    state = next;
    _persist();
    _pump();
    _notify();
    return true;
  }

  Future<void> waitFor(int id) => _finishes[id]?.future ?? Future.value();

  void _put(int id, TelegramDownload job) {
    if (ref.mounted) {
      state = {...state, id: job};
      _notify();
    }
  }

  void language(String code) {
    if (_language != code) {
      _language = code;
      _activitySummary = null;
      _notify();
    }
  }

  void _notify() {
    final summary = (
      state.values.where((e) => e.active).length,
      state.values.where((e) => e.phase == TelegramDownloadPhase.queued).length,
    );
    if (summary == _activitySummary) return;
    _activitySummary = summary;
    final activity = ref.read(telegramDownloadActivityProvider);
    unawaited(activity.update(summary.$1, summary.$2, languageCode: _language));
    if (summary.$1 > 0) {
      _heartbeat ??= Timer.periodic(const Duration(seconds: 15), (_) {
        if (ref.mounted) {
          final current = _activitySummary ?? (0, 0);
          unawaited(
            activity.update(current.$1, current.$2, languageCode: _language),
          );
        }
      });
    } else {
      _heartbeat?.cancel();
      _heartbeat = null;
    }
  }

  void _pump() {
    if (!ref.mounted ||
        _restoring ||
        _pausingAll ||
        ref.read(telegramProvider).auth != TelegramAuth.ready) {
      return;
    }
    for (final job in state.values.toList()) {
      if (_running.length >= _limit) break;
      final id = job.audio.fileId;
      if (job.phase != TelegramDownloadPhase.queued ||
          _running.contains(id) ||
          _stopping.contains(id)) {
        continue;
      }
      _running.add(id);
      final generation = (_generation[id] ?? 0) + 1;
      _generation[id] = generation;
      _put(id, job.copyWith(phase: TelegramDownloadPhase.receiving));
      unawaited(_run(job, generation));
    }
  }

  bool _current(int id, int generation) =>
      ref.mounted && _generation[id] == generation;

  Future<void> _run(TelegramDownload initial, int generation) async {
    final id = initial.audio.fileId;
    final finish = _finishes[id];
    final repository = ref.read(telegramRepositoryProvider);
    final sync = ref.read(telegramLibrarySyncProvider);
    try {
      final path = await repository.download(
        initial.audio,
        onProgress: (progress) {
          if (!_current(id, generation)) return;
          _pendingProgress[id] = progress;
          if (progress.saving) {
            _flushProgress();
          } else {
            _flush ??= Timer(const Duration(milliseconds: 250), _flushProgress);
          }
        },
      );
      if (!_current(id, generation)) return;
      _pendingProgress.remove(id);
      try {
        await repository.bind(initial.audio.key, path);
      } catch (error, stackTrace) {
        // Publication already succeeded. An index write cannot turn a valid
        // saved file into a failed download or make Retry download it again.
        TelegramDiagnostics.report(
          'Indexing a published audio file',
          error,
          stackTrace,
        );
      }
      if (!_current(id, generation)) return;
      final latest = state[id]!;
      _put(
        id,
        latest.copyWith(
          phase: TelegramDownloadPhase.completed,
          path: path,
          received: latest.total > 0 ? latest.total : initial.audio.size,
          bytesPerSecond: 0,
        ),
      );
      try {
        await sync();
      } catch (error, stackTrace) {
        TelegramDiagnostics.report(
          'Refreshing the device music library',
          error,
          stackTrace,
        );
      }
      if (_current(id, generation) && initial.playWhenReady) {
        final audio = initial.audio;
        await ref.read(telegramDownloadPlayerProvider)(
          Song(
            id: -audio.fileId,
            title: audio.title.isEmpty ? audio.fileName : audio.title,
            artist: audio.artist,
            album: '',
            albumId: -1,
            artistId: -1,
            duration: Duration(seconds: audio.duration),
            path: path,
            sizeBytes: audio.size,
            dateAddedSeconds: audio.date,
          ),
        );
      }
    } on TelegramTransferInterrupted {
      /* Pause/cancel already committed their state. */
    } catch (e) {
      if (_current(id, generation) &&
          state[id] != null &&
          state[id]!.phase != TelegramDownloadPhase.completed) {
        _put(
          id,
          state[id]!.copyWith(
            phase: TelegramDownloadPhase.failed,
            failure: e is TelegramException
                ? e.failure
                : TelegramFailure.generic,
            bytesPerSecond: 0,
          ),
        );
        final failure = e is TelegramException
            ? e.failure
            : TelegramFailure.generic;
        if (failure == TelegramFailure.network ||
            failure == TelegramFailure.flood ||
            failure == TelegramFailure.storage) {
          for (final queued in state.values.where(
            (job) => job.phase == TelegramDownloadPhase.queued,
          )) {
            final waiting = _finishes.remove(queued.audio.fileId);
            if (waiting != null && !waiting.isCompleted) waiting.complete();
          }
          state = {
            for (final entry in state.entries)
              entry.key: entry.value.phase == TelegramDownloadPhase.queued
                  ? entry.value.copyWith(
                      phase: TelegramDownloadPhase.paused,
                      failure: failure,
                    )
                  : entry.value,
          };
          _notify();
        }
      }
    } finally {
      _running.remove(id);
      _samples.remove(id);
      _pendingProgress.remove(id);
      if (identical(_finishes[id], finish)) _finishes.remove(id);
      if (finish != null && !finish.isCompleted) finish.complete();
      if (ref.mounted && !state.containsKey(id)) _generation.remove(id);
      if (ref.mounted) {
        _persist();
        _pump();
      }
    }
  }

  void _flushProgress() {
    _flush?.cancel();
    _flush = null;
    if (!ref.mounted) return;
    final now = DateTime.now();
    final next = Map<int, TelegramDownload>.of(state);
    for (final entry in _pendingProgress.entries) {
      final job = next[entry.key];
      if (job == null || !job.active) continue;
      final progress = entry.value;
      final old = _samples[entry.key];
      var speed = job.bytesPerSecond;
      if (old != null && progress.received >= old.$2) {
        final seconds = now.difference(old.$1).inMilliseconds / 1000;
        if (seconds > 0) {
          final instantaneous = (progress.received - old.$2) / seconds;
          speed = instantaneous == 0
              ? 0
              : speed == 0
              ? instantaneous
              : speed * 0.7 + instantaneous * 0.3;
        }
      }
      _samples[entry.key] = (now, progress.received);
      next[entry.key] = job.copyWith(
        phase: progress.saving
            ? TelegramDownloadPhase.saving
            : TelegramDownloadPhase.receiving,
        received: progress.received,
        total: progress.total > 0 ? progress.total : job.total,
        bytesPerSecond: progress.saving ? 0 : speed,
      );
    }
    _pendingProgress.clear();
    state = next;
  }

  Future<void> pause(int id, {bool discard = false}) async {
    final job = state[id];
    if (job == null ||
        job.phase == TelegramDownloadPhase.saving ||
        job.phase == TelegramDownloadPhase.completed) {
      return;
    }
    if (!_stopping.add(id)) return;
    _generation[id] = (_generation[id] ?? 0) + 1;
    _pendingProgress.remove(id);
    _put(
      id,
      job.copyWith(
        phase: discard
            ? TelegramDownloadPhase.canceled
            : TelegramDownloadPhase.paused,
        bytesPerSecond: 0,
        playWhenReady: false,
      ),
    );
    final completion = _finishes.remove(id);
    if (completion != null && !completion.isCompleted) completion.complete();
    try {
      await ref
          .read(telegramRepositoryProvider)
          .cancelDownload(id, discard: discard);
    } catch (e) {
      if (ref.mounted && state[id] != null) {
        _put(
          id,
          state[id]!.copyWith(
            phase: TelegramDownloadPhase.failed,
            failure: e is TelegramException
                ? e.failure
                : TelegramFailure.generic,
          ),
        );
      }
    }
    _stopping.remove(id);
    if (ref.mounted) {
      _persist();
      _pump();
    }
  }

  void resume(int id) {
    final job = state[id];
    if (job == null || job.active) return;
    _finishes[id] = Completer<void>();
    _put(
      id,
      job.copyWith(
        phase: TelegramDownloadPhase.queued,
        received: job.phase == TelegramDownloadPhase.paused ? job.received : 0,
        bytesPerSecond: 0,
      ),
    );
    _persist();
    _pump();
  }

  Future<void> pauseAll() async {
    _pausingAll = true;
    try {
      for (final id in state.keys.toList()) {
        final phase = state[id]!.phase;
        if (phase == TelegramDownloadPhase.receiving ||
            phase == TelegramDownloadPhase.queued) {
          await pause(id);
        }
      }
    } finally {
      _pausingAll = false;
    }
  }

  void resumeAll() {
    for (final id in state.keys.toList()) {
      final phase = state[id]!.phase;
      if (phase == TelegramDownloadPhase.paused ||
          phase == TelegramDownloadPhase.failed) {
        resume(id);
      }
    }
  }

  Future<void> prepareLogout() async {
    _closing = true;
    await pauseAll();
    final committing = state.values
        .where((job) => job.phase == TelegramDownloadPhase.saving)
        .map((job) => job.audio.fileId)
        .toList();
    await Future.wait(committing.map(waitFor));
    await _persisting.catchError((Object _) {});
  }

  void unlock() {
    _closing = false;
  }

  void clearFinished() {
    for (final entry in state.entries) {
      if (_canClearDownload(entry.value) && !_running.contains(entry.key)) {
        _generation.remove(entry.key);
      }
    }
    state = Map.fromEntries(
      state.entries.where((e) => !_canClearDownload(e.value)),
    );
    _notify();
    _persist();
  }

  void _persist() {
    if (_closing) return;
    final snapshot = state.values
        .where((e) => e.unfinished || e.phase == TelegramDownloadPhase.failed)
        .take(maxQueue)
        .map((e) => e.audio)
        .toList();
    final repository = ref.read(telegramRepositoryProvider);
    _persisting = _persisting.catchError((Object _) {}).then<void>((_) async {
      if (!ref.mounted) return;
      await repository.saveTransfers(snapshot);
    });
    unawaited(_persisting.catchError((Object _) {}));
  }
}

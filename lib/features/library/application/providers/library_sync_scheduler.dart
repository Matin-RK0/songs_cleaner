import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_controller.dart';

/// App-wide scheduler that keeps the library fresh with an optimized
/// incremental scan: on resume (throttled) and on a slow timer while the app
/// stays visible. Songs imported outside the app (e.g. a file manager) appear
/// without a manual reload.
///
/// The underlying MediaStore query has no date filter, so every check reads
/// the full song list. The interval and cooldowns are deliberately
/// conservative, and the timer is fully paused when the app is not visible, to
/// keep battery impact negligible on low-end devices.
final librarySyncSchedulerProvider = Provider<LibrarySyncScheduler>((ref) {
  final scheduler = LibrarySyncScheduler(
    onSync: () => ref.read(libraryProvider.notifier).syncNewSongs(),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler..start();
});

class LibrarySyncScheduler {
  LibrarySyncScheduler({
    required this.onSync,
    this.interval = const Duration(minutes: 5),
    this.resumeCooldown = const Duration(minutes: 2),
  });

  final Future<void> Function() onSync;

  /// Slow fallback while the app stays open.
  final Duration interval;

  /// Minimum gap between resume-triggered checks, so quickly switching apps
  /// does not repeat the MediaStore read.
  final Duration resumeCooldown;

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _syncing = false;
  DateTime? _lastSyncAt;

  void start() {
    _lastSyncAt = DateTime.now();
    _lifecycle = AppLifecycleListener(
      onResume: _onResumed,
      onShow: _startTimer,
      onHide: _stopTimer,
      onPause: _stopTimer,
      onInactive: _stopTimer,
    );
    _startTimer();
  }

  void _onResumed() {
    _startTimer();
    final last = _lastSyncAt;
    if (last != null && DateTime.now().difference(last) < resumeCooldown) {
      return;
    }
    unawaited(_run());
  }

  void _startTimer() {
    _timer ??= Timer.periodic(interval, (_) => unawaited(_run()));
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _run() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await onSync();
    } catch (_) {
      // Best-effort check; a transient MediaStore failure is retried on the
      // next tick or resume.
    } finally {
      _syncing = false;
      _lastSyncAt = DateTime.now();
    }
  }

  void dispose() {
    _stopTimer();
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../infrastructure/lock_screen_service.dart';

/// Native bridge singleton for the lock-screen feature.
final lockScreenServiceProvider = Provider<LockScreenService>((ref) {
  final service = LockScreenService();
  ref.onDispose(service.dispose);
  return service;
});

/// Settings-level state for the "music controls on lock screen" feature.
class LockScreenState {
  const LockScreenState({
    required this.supported,
    required this.overlayGranted,
    required this.enabled,
    this.callStateGranted = false,
    this.timeoutSeconds = 5,
  });

  /// Device/OS supports the feature (Android only).
  final bool supported;

  /// "Display over other apps" permission is granted.
  final bool overlayGranted;

  /// Required to keep the custom lock screen out of the way of phone calls.
  final bool callStateGranted;

  /// Only true when supported and both overlay and call-state access are granted.
  final bool enabled;
  final int timeoutSeconds;

  LockScreenState copyWith({
    bool? supported,
    bool? overlayGranted,
    bool? enabled,
    bool? callStateGranted,
    int? timeoutSeconds,
  }) {
    return LockScreenState(
      supported: supported ?? this.supported,
      overlayGranted: overlayGranted ?? this.overlayGranted,
      enabled: enabled ?? this.enabled,
      callStateGranted: callStateGranted ?? this.callStateGranted,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}

final lockScreenControllerProvider =
    AsyncNotifierProvider<LockScreenController, LockScreenState>(
      LockScreenController.new,
    );

/// Owns the toggle and gates it on overlay and call-state permissions.
/// Revoking either permission in system settings disables the custom player.
class LockScreenController extends AsyncNotifier<LockScreenState> {
  @override
  Future<LockScreenState> build() async {
    final service = ref.watch(lockScreenServiceProvider);
    final settings = ref.watch(appSettingsRepositoryProvider);

    final supported = await service.isSupported();
    final overlayGranted = supported && await service.hasOverlayPermission();
    final callStateGranted =
        supported && await service.hasCallStatePermission();
    final enabled =
        supported &&
        overlayGranted &&
        callStateGranted &&
        settings.loadLockScreenEnabled(false);

    final timeoutSeconds = settings.loadLockScreenTimeoutSeconds();
    if (supported) {
      await service.setTimeoutSeconds(timeoutSeconds);
      await service.setEnabled(enabled);
    }
    return LockScreenState(
      supported: supported,
      overlayGranted: overlayGranted,
      enabled: enabled,
      callStateGranted: callStateGranted,
      timeoutSeconds: timeoutSeconds,
    );
  }

  Future<bool> setEnabled(bool value) async {
    final current = state.value;
    if (current == null) return false;
    if (value &&
        (!current.supported ||
            !current.overlayGranted ||
            !await ref
                .read(lockScreenServiceProvider)
                .hasCallStatePermission())) {
      return false;
    }
    state = AsyncData(current.copyWith(enabled: value));
    await ref.read(appSettingsRepositoryProvider).saveLockScreenEnabled(value);
    await ref.read(lockScreenServiceProvider).setEnabled(value);
    return true;
  }

  Future<bool> requestCallStatePermission() async {
    final granted = await ref
        .read(lockScreenServiceProvider)
        .requestCallStatePermission();
    await refreshPermission();
    return granted;
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    final current = state.value;
    if (current == null) return;
    await ref
        .read(appSettingsRepositoryProvider)
        .saveLockScreenTimeoutSeconds(seconds);
    await ref.read(lockScreenServiceProvider).setTimeoutSeconds(seconds);
    state = AsyncData(current.copyWith(timeoutSeconds: seconds));
  }

  /// Opens the system screen that grants "Display over other apps".
  Future<void> requestOverlayPermission() =>
      ref.read(lockScreenServiceProvider).requestOverlayPermission();

  /// Re-reads permissions, e.g. after returning from system settings.
  Future<void> refreshPermission() async {
    final service = ref.read(lockScreenServiceProvider);
    final supported = state.value?.supported ?? await service.isSupported();
    final overlayGranted = supported && await service.hasOverlayPermission();
    final callStateGranted =
        supported && await service.hasCallStatePermission();
    final wasEnabled = state.value?.enabled ?? false;
    final enabled =
        supported && overlayGranted && callStateGranted && wasEnabled;
    state = AsyncData(
      LockScreenState(
        supported: supported,
        overlayGranted: overlayGranted,
        enabled: enabled,
        callStateGranted: callStateGranted,
        timeoutSeconds:
            state.value?.timeoutSeconds ??
            ref
                .read(appSettingsRepositoryProvider)
                .loadLockScreenTimeoutSeconds(),
      ),
    );
    if ((!overlayGranted || !callStateGranted) && wasEnabled) {
      await ref
          .read(appSettingsRepositoryProvider)
          .saveLockScreenEnabled(false);
      await service.setEnabled(false);
    }
  }
}

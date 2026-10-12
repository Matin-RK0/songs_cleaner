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
  });

  /// Device/OS supports the feature (Android only).
  final bool supported;

  /// "Display over other apps" permission is granted.
  final bool overlayGranted;

  /// User toggle. Only ever true when [supported] and [overlayGranted].
  final bool enabled;

  LockScreenState copyWith({
    bool? supported,
    bool? overlayGranted,
    bool? enabled,
  }) {
    return LockScreenState(
      supported: supported ?? this.supported,
      overlayGranted: overlayGranted ?? this.overlayGranted,
      enabled: enabled ?? this.enabled,
    );
  }
}

final lockScreenControllerProvider =
    AsyncNotifierProvider<LockScreenController, LockScreenState>(
  LockScreenController.new,
);

/// Resolves platform support and the overlay permission, and owns the user
/// toggle. The stored preference is only honored while the permission is held,
/// so revoking permission in system settings cleanly disables the feature.
class LockScreenController extends AsyncNotifier<LockScreenState> {
  @override
  Future<LockScreenState> build() async {
    final service = ref.watch(lockScreenServiceProvider);
    final settings = ref.watch(appSettingsRepositoryProvider);

    final supported = await service.isSupported();
    final overlayGranted = supported && await service.hasOverlayPermission();
    final enabled =
        supported && overlayGranted && settings.loadLockScreenEnabled(false);

    if (supported) await service.setEnabled(enabled);
    return LockScreenState(
      supported: supported,
      overlayGranted: overlayGranted,
      enabled: enabled,
    );
  }

  Future<void> setEnabled(bool value) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(enabled: value));
    await ref.read(appSettingsRepositoryProvider).saveLockScreenEnabled(value);
    await ref.read(lockScreenServiceProvider).setEnabled(value);
  }

  /// Opens the system screen that grants "Display over other apps".
  Future<void> requestOverlayPermission() =>
      ref.read(lockScreenServiceProvider).requestOverlayPermission();

  /// Re-reads the overlay permission, e.g. after returning from settings.
  Future<void> refreshPermission() async {
    final service = ref.read(lockScreenServiceProvider);
    final supported = state.value?.supported ?? await service.isSupported();
    final overlayGranted = supported && await service.hasOverlayPermission();
    state = AsyncData(
      LockScreenState(
        supported: supported,
        overlayGranted: overlayGranted,
        enabled: state.value?.enabled ?? false,
      ),
    );
  }
}

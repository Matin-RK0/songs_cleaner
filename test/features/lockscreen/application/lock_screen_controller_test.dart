import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/lockscreen/application/providers/lock_screen_controller.dart';
import 'package:songs_cleaner/features/lockscreen/infrastructure/lock_screen_service.dart';

class _LockScreenService extends LockScreenService {
  bool callPermission = false;
  bool grantOnRequest = false;
  int permissionRequests = 0;
  final enabledValues = <bool>[];

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> hasOverlayPermission() async => true;

  @override
  Future<bool> hasCallStatePermission() async => callPermission;

  @override
  Future<bool> requestCallStatePermission() async {
    permissionRequests++;
    return callPermission = grantOnRequest;
  }

  @override
  Future<void> setEnabled(bool enabled) async => enabledValues.add(enabled);

  @override
  Future<void> setTimeoutSeconds(int seconds) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> createContainer(
    _LockScreenService service, {
    bool savedEnabled = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'lockscreen.enabled': savedEnabled,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        lockScreenServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(() {
      container.dispose();
      service.dispose();
    });
    await container.read(lockScreenControllerProvider.future);
    return container;
  }

  test(
    'an old enabled preference cannot bypass phone-state permission',
    () async {
      final service = _LockScreenService();
      final container = await createContainer(service, savedEnabled: true);
      expect(
        container.read(lockScreenControllerProvider).value!.enabled,
        isFalse,
      );
      expect(service.enabledValues, [false]);
      expect(service.permissionRequests, 0);
    },
  );

  test(
    'enabling without permission is rejected without prompting silently',
    () async {
      final service = _LockScreenService();
      final container = await createContainer(service);
      final controller = container.read(lockScreenControllerProvider.notifier);
      expect(await controller.setEnabled(true), isFalse);
      expect(service.enabledValues, [false]);
      expect(service.permissionRequests, 0);
    },
  );

  test('explicit grant allows enabling', () async {
    final service = _LockScreenService()..grantOnRequest = true;
    final container = await createContainer(service);
    final controller = container.read(lockScreenControllerProvider.notifier);
    expect(await controller.requestCallStatePermission(), isTrue);
    expect(await controller.setEnabled(true), isTrue);
    expect(container.read(lockScreenControllerProvider).value!.enabled, isTrue);
    expect(service.enabledValues, [false, true]);
  });

  test('denying permission leaves the feature disabled', () async {
    final service = _LockScreenService();
    final container = await createContainer(service);
    final controller = container.read(lockScreenControllerProvider.notifier);
    expect(await controller.requestCallStatePermission(), isFalse);
    expect(await controller.setEnabled(true), isFalse);
    expect(
      container.read(lockScreenControllerProvider).value!.enabled,
      isFalse,
    );
  });

  test('revoking phone-state permission disables an active feature', () async {
    final service = _LockScreenService()..callPermission = true;
    final container = await createContainer(service, savedEnabled: true);
    service.callPermission = false;
    await container
        .read(lockScreenControllerProvider.notifier)
        .refreshPermission();
    expect(
      container.read(lockScreenControllerProvider).value!.enabled,
      isFalse,
    );
    expect(service.enabledValues, [true, false]);
    expect(
      container.read(appSettingsRepositoryProvider).loadLockScreenEnabled(true),
      isFalse,
    );
  });
}

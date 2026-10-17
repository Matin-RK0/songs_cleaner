import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';

/// When true, the "previous" control always jumps to the previous queue item
/// instead of restarting the current song first. Applies to every previous
/// control: player screen, mini player, lock-screen player and the media
/// notification.
final previousGoesToPreviousProvider =
    NotifierProvider<PreviousGoesToPreviousController, bool>(
      PreviousGoesToPreviousController.new,
    );

class PreviousGoesToPreviousController extends Notifier<bool> {
  @override
  bool build() => ref
      .watch(appSettingsRepositoryProvider)
      .loadPreviousGoesToPrevious(false);

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref
        .read(appSettingsRepositoryProvider)
        .savePreviousGoesToPrevious(value);
  }
}

/// Controls whether the destructive quick-delete action is hidden from the
/// full-screen player. It is opt-in so existing users keep the button visible.
final hideQuickDeleteProvider =
    NotifierProvider<HideQuickDeleteController, bool>(
      HideQuickDeleteController.new,
    );

class HideQuickDeleteController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appSettingsRepositoryProvider).loadHideQuickDelete(false);

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(appSettingsRepositoryProvider).saveHideQuickDelete(value);
  }
}

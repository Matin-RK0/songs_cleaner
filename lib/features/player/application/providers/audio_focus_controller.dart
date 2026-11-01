import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../domain/audio_focus_mode.dart';

final audioDuckingPercentProvider =
    NotifierProvider<AudioDuckingPercentController, int>(
      AudioDuckingPercentController.new,
    );

class AudioDuckingPercentController extends Notifier<int> {
  @override
  int build() =>
      ref.watch(appSettingsRepositoryProvider).loadAudioDuckingPercent();

  Future<void> setPercent(int percent) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    await repository.saveAudioDuckingPercent(percent);
    if (ref.mounted) state = repository.loadAudioDuckingPercent();
  }
}

final audioFocusModeProvider =
    NotifierProvider<AudioFocusModeController, AudioFocusMode>(
      AudioFocusModeController.new,
    );

class AudioFocusModeController extends Notifier<AudioFocusMode> {
  @override
  AudioFocusMode build() {
    final index = ref
        .watch(appSettingsRepositoryProvider)
        .loadAudioFocusMode(AudioFocusMode.pause.index)
        .clamp(0, AudioFocusMode.values.length - 1);
    return AudioFocusMode.values[index];
  }

  Future<void> setMode(AudioFocusMode mode) async {
    state = mode;
    await ref
        .read(appSettingsRepositoryProvider)
        .saveAudioFocusMode(mode.index);
  }
}

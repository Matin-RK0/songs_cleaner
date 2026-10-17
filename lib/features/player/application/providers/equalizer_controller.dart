import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../models/equalizer_state.dart';

final androidEqualizerProvider = Provider<AndroidEqualizer>(
  (ref) =>
      throw UnimplementedError('Override androidEqualizerProvider in main'),
);

final equalizerProvider =
    AsyncNotifierProvider<EqualizerController, EqualizerState>(
      EqualizerController.new,
    );

class EqualizerController extends AsyncNotifier<EqualizerState> {
  @override
  Future<EqualizerState> build() async {
    if (!Platform.isAndroid) return const EqualizerState.unsupported();
    final effect = ref.read(androidEqualizerProvider);
    final parameters = await effect.parameters;
    final savedGains = ref
        .read(appSettingsRepositoryProvider)
        .loadEqualizerGains();
    final bands = parameters.bands
        .asMap()
        .entries
        .map((entry) {
          final gain = entry.key < savedGains.length
              ? savedGains[entry.key]
                    .clamp(parameters.minDecibels, parameters.maxDecibels)
                    .toDouble()
              : entry.value.gain;
          return EqualizerBandState(
            frequency: entry.value.centerFrequency,
            gain: gain,
          );
        })
        .toList(growable: false);
    for (var index = 0; index < bands.length; index++) {
      await parameters.bands[index].setGain(bands[index].gain);
    }
    final enabled = ref
        .read(appSettingsRepositoryProvider)
        .loadEqualizerEnabled(false);
    await effect.setEnabled(enabled);
    return EqualizerState(
      supported: true,
      enabled: enabled,
      minGain: parameters.minDecibels,
      maxGain: parameters.maxDecibels,
      bands: List.unmodifiable(bands),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null || !current.supported) return;
    await ref.read(androidEqualizerProvider).setEnabled(enabled);
    await ref.read(appSettingsRepositoryProvider).saveEqualizerEnabled(enabled);
    state = AsyncData(
      EqualizerState(
        supported: true,
        enabled: enabled,
        minGain: current.minGain,
        maxGain: current.maxGain,
        bands: current.bands,
      ),
    );
  }

  Future<void> setGain(int index, double gain) async {
    final current = state.value;
    if (current == null || index < 0 || index >= current.bands.length) return;
    final effect = ref.read(androidEqualizerProvider);
    final parameters = await effect.parameters;
    final normalized = gain.clamp(current.minGain, current.maxGain).toDouble();
    await parameters.bands[index].setGain(normalized);
    final bands = [...current.bands];
    bands[index] = EqualizerBandState(
      frequency: bands[index].frequency,
      gain: normalized,
    );
    state = AsyncData(
      EqualizerState(
        supported: true,
        enabled: current.enabled,
        minGain: current.minGain,
        maxGain: current.maxGain,
        bands: List.unmodifiable(bands),
      ),
    );
    await ref
        .read(appSettingsRepositoryProvider)
        .saveEqualizerGains(bands.map((band) => band.gain).toList());
  }

  Future<void> reset() async {
    final current = state.value;
    if (current == null || !current.supported) return;
    for (var index = 0; index < current.bands.length; index++) {
      await setGain(index, 0);
    }
  }
}

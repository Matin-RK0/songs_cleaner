import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/library/infrastructure/data_sources/device_music_data_source.dart';
import 'features/player/application/providers/player_controller.dart';

const _pendingColdStartPlayKey = 'pendingColdStartPlay';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final player = AudioPlayer();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettingsRepository(prefs);
  final shouldResumePlayback =
      prefs.getBool(_pendingColdStartPlayKey) ?? false;
  if (shouldResumePlayback) {
    // The Android receiver stores this before audio_service's Dart callback is
    // ready. Consume it first so a process crash cannot replay it indefinitely.
    await prefs.remove(_pendingColdStartPlayKey);
  }
  final handler = await initializeMusicPlayerHandler(
    player: player,
    settings: settings,
  );
  if (shouldResumePlayback) {
    try {
      if (handler.currentSong != null) {
        await handler.play();
      } else {
        final newestSong = await DeviceMusicDataSource(
          OnAudioQuery(),
        ).fetchNewestExistingSong();
        if (newestSong != null) {
          await handler.loadAndPlay([newestSong]);
        }
      }
    } catch (_) {
      // A missing file or unavailable MediaStore must not prevent the Flutter
      // Activity from opening after an external media command.
    }
  }

  // Create MediaSession before rendering so system play requests can restore
  // and start the persisted track even when no player screen was opened yet.
  runApp(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        sharedPreferencesProvider.overrideWithValue(prefs),
        musicPlayerHandlerProvider.overrideWithValue(handler),
      ],
      child: const SongsCleanerApp(),
    ),
  );
}

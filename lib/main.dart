import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/player/application/providers/player_controller.dart';
import 'features/player/application/providers/equalizer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final equalizer = AndroidEqualizer();
  final player = AudioPlayer(
    handleInterruptions: false,
    audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
  );
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettingsRepository(prefs);
  final handler = await initializeMusicPlayerHandler(
    player: player,
    settings: settings,
  );
  // Create the single MediaSession before rendering. Android media buttons,
  // Samsung Routines, the notification and the lock screen all target this
  // same handler, even when no player screen has been opened.
  runApp(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        sharedPreferencesProvider.overrideWithValue(prefs),
        musicPlayerHandlerProvider.overrideWithValue(handler),
        androidEqualizerProvider.overrideWithValue(equalizer),
      ],
      child: const SongsCleanerApp(),
    ),
  );
}

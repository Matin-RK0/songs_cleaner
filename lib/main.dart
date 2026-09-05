import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/player/application/providers/player_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final player = AudioPlayer();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettingsRepository(prefs);
  final handler = await initializeMusicPlayerHandler(
    player: player,
    settings: settings,
  );

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

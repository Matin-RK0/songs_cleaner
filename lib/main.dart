import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/player/application/providers/player_controller.dart';
import 'features/player/infrastructure/music_player_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final player = AudioPlayer();
  final prefs = await SharedPreferences.getInstance();
  // Audio focus setup is best effort: a transient platform audio-session
  // failure must not prevent the library screen from opening.
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (_) {
    // Continue with the platform defaults; playback can still be initialized.
  }

  final settings = AppSettingsRepository(prefs);
  late final MusicPlayerHandler handler;
  try {
    handler = await AudioService.init<MusicPlayerHandler>(
      builder: () => MusicPlayerHandler(player, settings: settings),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.songs_cleaner.playback',
        androidNotificationChannelName: 'پخش موزیک',
        androidNotificationIcon: 'drawable/ic_notif_applogo',
        // Keep the media service in the foreground while paused. Android 12+
        // otherwise blocks a later media-button action when the activity has
        // been swiped away because restarting foreground service is restricted.
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
      ),
    );
  } catch (_) {
    // Still launch the app if the notification service is temporarily
    // unavailable (for example immediately after an OS process reclaim).
    handler = MusicPlayerHandler(player, settings: settings);
  }

  runApp(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        musicPlayerHandlerProvider.overrideWithValue(handler),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SongsCleanerApp(),
    ),
  );
}

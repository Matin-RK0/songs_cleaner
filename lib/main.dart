import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/player/application/providers/player_controller.dart';
import 'features/player/infrastructure/routine_playback_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final player = AudioPlayer();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettingsRepository(prefs);
  // Cold-start Play is handled by RoutinePlaybackService natively. Remove the
  // flag left by earlier app versions so it cannot race the native player.
  await prefs.remove('pendingColdStartPlay');
  final handler = await initializeMusicPlayerHandler(
    player: player,
    settings: settings,
  );
  // If Samsung Modes and Routines already started playback natively while the
  // app was closed, adopt its live position instead of letting a second stream
  // start. Otherwise keep the native session armed as a fallback.
  final handoff = await RoutinePlaybackService.handoff();
  if (handoff == null && !player.playing) {
    await RoutinePlaybackService.arm();
  }
  // Create MediaSession before rendering so system play requests can restore
  // and start the persisted track even when no player screen was opened yet.
  runApp(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        sharedPreferencesProvider.overrideWithValue(prefs),
        musicPlayerHandlerProvider.overrideWithValue(handler),
        routinePlaybackHandoffProvider.overrideWithValue(handoff),
      ],
      child: const SongsCleanerApp(),
    ),
  );
}

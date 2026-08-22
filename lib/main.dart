import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'app/app.dart';
import 'features/player/application/providers/player_controller.dart';
import 'features/player/infrastructure/music_player_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final player = AudioPlayer();
  final handler = await AudioService.init(
    builder: () => MusicPlayerHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.songs_cleaner.playback',
      androidNotificationChannelName: 'پخش موزیک',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(player),
        musicPlayerHandlerProvider.overrideWithValue(handler),
      ],
      child: const SongsCleanerApp(),
    ),
  );
}

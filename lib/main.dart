import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'app/app.dart';
import 'core/settings/app_settings_repository.dart';
import 'features/player/application/providers/player_controller.dart';
import 'features/player/application/providers/equalizer_controller.dart';
import 'features/library/infrastructure/data_sources/device_music_data_source.dart';
import 'features/library/domain/entities/song.dart';
import 'features/playlists/infrastructure/repositories/playlist_repository_impl.dart';

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
  final musicSource = DeviceMusicDataSource(OnAudioQuery());
  final playlistRepository = PlaylistRepositoryImpl(prefs);
  final handler = await initializeMusicPlayerHandler(
    player: player,
    settings: settings,
    mediaCatalog: (parentId) async {
      final songs = await musicSource.fetchSongs();
      MediaItem itemForSong(Song song) => MediaItem(
        id: 'song_${song.id}',
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        playable: true,
        extras: {'path': song.path},
      );
      if (parentId == 'root') {
        return [
          const MediaItem(id: 'library', title: 'Library', playable: false),
          const MediaItem(id: 'queue', title: 'Queue', playable: false),
          ...playlistRepository.loadPlaylists().map(
            (playlist) => MediaItem(
              id: 'playlist:${playlist.id}',
              title: playlist.name,
              playable: false,
            ),
          ),
        ];
      }
      if (parentId == 'library') return songs.map(itemForSong).toList();
      if (parentId.startsWith('playlist:')) {
        final id = parentId.substring('playlist:'.length);
        final matching = playlistRepository
            .loadPlaylists()
            .where((item) => item.id == id)
            .toList(growable: false);
        final playlist = matching.isEmpty ? null : matching.first;
        if (playlist == null) return const <MediaItem>[];
        final songById = {for (final song in songs) song.id: song};
        return playlist.songIds
            .map((id) => songById[id])
            .whereType<Song>()
            .map(itemForSong)
            .toList();
      }
      return const <MediaItem>[];
    },
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

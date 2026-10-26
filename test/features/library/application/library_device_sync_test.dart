import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/library/application/providers/library_controller.dart';
import 'package:songs_cleaner/features/library/application/providers/library_sync_scheduler.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_filter.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_sort.dart';
import 'package:songs_cleaner/features/library/infrastructure/data_sources/device_music_data_source.dart';
import 'package:songs_cleaner/features/library/infrastructure/media_permissions_service.dart';

class _Permissions extends Fake implements MediaPermissionsService {
  @override
  Future<bool> requestAudioAccess() async => true;
}

class _DeviceMusic extends Fake implements DeviceMusicDataSource {
  List<Song> songs = [];
  Completer<List<Song>>? nextRead;
  Completer<List<Song>>? nextIncrementalRead;
  int reads = 0;
  int incrementalReads = 0;

  @override
  Future<List<Song>> fetchSongs() async {
    reads++;
    final pending = nextRead;
    nextRead = null;
    return pending == null ? songs : pending.future;
  }

  @override
  Future<List<Song>> fetchSongsNewerThan(int dateAddedSeconds) async {
    incrementalReads++;
    final pending = nextIncrementalRead;
    nextIncrementalRead = null;
    return pending == null ? songs : pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late _DeviceMusic source;
  late LibraryController controller;

  Future<Song> song(int id, {String title = 'Song', int date = 100}) async {
    final file = File('${directory.path}/$id.mp3');
    await file.writeAsBytes([1, 2, 3]);
    return Song(
      id: id,
      title: title,
      artist: 'Artist',
      album: 'Album',
      albumId: 1,
      artistId: 1,
      duration: const Duration(minutes: 3),
      path: file.path,
      sizeBytes: 3,
      dateAddedSeconds: date,
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('library-device-sync-');
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    source = _DeviceMusic()..songs = [await song(1), await song(2)];
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        mediaPermissionsProvider.overrideWithValue(_Permissions()),
        deviceMusicDataSourceProvider.overrideWithValue(source),
      ],
    );
    await container.read(libraryProvider.future);
    controller = container.read(libraryProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await directory.delete(recursive: true);
  });

  test('songs-tab entry reconciles added, deleted and edited music', () async {
    final edited = await song(1, title: 'Updated title');
    final deleted = source.songs[1];
    await File(deleted.path).delete();
    // A new publication can carry an old date, and a deleted file can still
    // have a stale MediaStore row. Neither is handled by an additions-only sync.
    final added = await song(3, title: 'Telegram download', date: 1);
    source.songs = [edited, deleted, added];
    final scheduler = container.read(librarySyncSchedulerProvider);
    scheduler.onSongsTabSelected();
    await controller.syncDeviceChanges();

    final state = container.read(libraryProvider).requireValue;
    expect(state.songs.map((song) => song.id), [1, 3]);
    expect(state.songs.first.title, 'Updated title');
    expect(state.visibleSongs.map((song) => song.id), [3, 1]);
    expect(source.reads, 2);
    expect(source.incrementalReads, 0);
  });

  test(
    'keeps data visible and preserves controls edited during sync',
    () async {
      final pending = Completer<List<Song>>();
      source.nextRead = pending;
      final sync = controller.syncDeviceChanges();
      expect(container.read(libraryProvider).isLoading, isFalse);
      controller.setQuery('Updated');
      controller.setSort(SongSort.dateAddedDesc);
      controller.setFilter(SongFilter.missingMetadata);
      pending.complete([await song(1, title: 'Updated title'), await song(3)]);
      await sync;

      final state = container.read(libraryProvider).requireValue;
      expect(state.query, 'Updated');
      expect(state.sort, SongSort.dateAddedDesc);
      expect(state.filter, SongFilter.missingMetadata);
      expect(state.visibleSongs.single.title, 'Updated title');
    },
  );

  test('coalesces concurrent scans and retries after a failed scan', () async {
    final pending = Completer<List<Song>>();
    source.nextRead = pending;
    final first = controller.syncDeviceChanges();
    final second = controller.syncDeviceChanges();
    expect(identical(first, second), isTrue);
    expect(source.reads, 2);
    final failed = expectLater(first, throwsA(isA<FileSystemException>()));
    pending.completeError(const FileSystemException('MediaStore unavailable'));
    await failed;
    expect(container.read(libraryProvider).requireValue.songs.length, 2);
    source.songs = [];
    await controller.syncDeviceChanges();
    expect(container.read(libraryProvider).requireValue.songs, isEmpty);
    expect(source.reads, 3);
  });

  test('an old scan cannot restore a song deleted during its query', () async {
    final oldSongs = source.songs;
    final pending = Completer<List<Song>>();
    source.nextRead = pending;
    final sync = controller.syncDeviceChanges();
    controller.removeSongLocally(2);
    pending.complete(oldSongs);
    await sync;
    expect(
      container.read(libraryProvider).requireValue.songs.map((song) => song.id),
      [1],
    );
  });

  test('a stale incremental result cannot undo full reconciliation', () async {
    final oldSongs = source.songs;
    final pending = Completer<List<Song>>();
    source.nextIncrementalRead = pending;
    final incremental = controller.syncNewSongs();
    source.songs = [oldSongs.first];
    await controller.syncDeviceChanges();
    pending.complete(oldSongs);
    await incremental;
    expect(
      container.read(libraryProvider).requireValue.songs.map((song) => song.id),
      [1],
    );
  });

  test('a delayed scan cannot overwrite a newer manual refresh', () async {
    final oldSongs = source.songs;
    final pending = Completer<List<Song>>();
    source.nextRead = pending;
    final sync = controller.syncDeviceChanges();
    source.songs = [await song(3, title: 'Refreshed song')];
    await controller.refresh();
    pending.complete(oldSongs);
    await sync;
    expect(
      container.read(libraryProvider).requireValue.songs.single.title,
      'Refreshed song',
    );
  });

  test(
    'download sync waits for an older full scan before adding music',
    () async {
      final oldSongs = source.songs;
      final pending = Completer<List<Song>>();
      source.nextRead = pending;
      final full = controller.syncDeviceChanges();
      final added = await song(3, title: 'Just downloaded');
      source.songs = [...oldSongs, added];
      final download = controller.syncNewSongs();
      expect(source.incrementalReads, 0);
      pending.complete(oldSongs);
      await Future.wait([full, download]);
      expect(
        container
            .read(libraryProvider)
            .requireValue
            .songs
            .map((song) => song.id),
        contains(3),
      );
    },
  );
}

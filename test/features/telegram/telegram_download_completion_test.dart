import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_controller.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_chat_summary_provider.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';

import 'telegram_cache_test.dart' show FakeMusicPublisher;
import 'telegram_fakes.dart';
import 'telegram_local_matcher_test.dart' show localSong;

class _IndexFailureRepository extends FakeTelegramRepository {
  bool failIndexReads = false;
  bool failIndexWrites = false;

  @override
  Future<void> bind(String key, String path) async {
    if (failIndexWrites) {
      throw const FileSystemException('Index temporarily unavailable');
    }
    await super.bind(key, path);
  }

  @override
  Future<Map<String, String>> loadBindings() async {
    if (failIndexReads) {
      throw const FileSystemException('Index temporarily unavailable');
    }
    return super.loadBindings();
  }
}

class _SyncingLibrary extends LibraryController {
  int syncCalls = 0;
  bool failScan = false;
  Song? nextSong;

  @override
  Future<LibraryState> build() async =>
      const LibraryState(songs: [], visibleSongs: []);

  @override
  Future<void> syncNewSongs() async {
    syncCalls++;
    if (failScan) throw const FileSystemException('MediaStore scan delayed');
    final song = nextSong;
    if (song != null) {
      state = AsyncData(LibraryState(songs: [song], visibleSongs: [song]));
    }
  }
}

class _DelayedFiles extends FakeTelegramLocalFiles {
  Completer<Set<String>>? nextRead;

  @override
  Future<Set<String>> existingPaths(Iterable<String> paths) {
    final pending = nextRead;
    nextRead = null;
    return pending?.future ?? super.existingPaths(paths);
  }
}

class _PublicationRacePublisher extends FakeMusicPublisher {
  _PublicationRacePublisher(
    super.destination, {
    required this.indexPath,
    this.removeSource = false,
  });
  final String indexPath;
  final bool removeSource;

  @override
  Future<String> publish(String sourcePath, TelegramAudio audio) async {
    final path = await super.publish(sourcePath, audio);
    if (removeSource) {
      await File(sourcePath).delete();
    } else {
      await File(indexPath).delete();
      await Directory(indexPath).create();
    }
    return path;
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> setup(
    _IndexFailureRepository repository, {
    FakeTelegramLocalFiles? localFiles,
  }) async {
    final files = (localFiles ?? FakeTelegramLocalFiles())
      ..existing.add(repository.downloadedPath);
    final container = ProviderContainer(
      overrides: [
        telegramRepositoryProvider.overrideWithValue(repository),
        telegramLocalFilesProvider.overrideWithValue(files),
        libraryProvider.overrideWith(_SyncingLibrary.new),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    await container.read(libraryProvider.future);
    final chat = container.listen(telegramChatProvider(123), (_, _) {});
    addTearDown(chat.close);
    await _settle();
    repository.events.add(TelegramAuth.ready);
    await _settle();
    return container;
  }

  test(
    'a saved file is completed and immediately playable even when index writes fail',
    () async {
      final audio = testAudio();
      final repository = _IndexFailureRepository()
        ..savedAudio = [audio]
        ..page = TelegramAudioPage([audio], 0)
        ..failIndexWrites = true;
      final container = await setup(repository);
      final downloads = container.read(telegramDownloadsProvider.notifier);
      expect(downloads.enqueue(audio), isTrue);
      await downloads.waitFor(audio.fileId);
      await _settle();
      final job = container.read(telegramDownloadsProvider)[audio.fileId]!;
      expect(job.phase, TelegramDownloadPhase.completed);
      expect(job.failure, isNull);
      expect(container.read(telegramChatProvider(123)).failure, isNull);
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        repository.downloadedPath,
      );
      expect(
        await container.read(telegramChatLocalCountProvider(123).future),
        1,
      );
      expect(repository.bindings, isEmpty);
      expect(repository.downloadCalls, 1);
      downloads.clearFinished();
      await _settle();
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        repository.downloadedPath,
      );
      expect(container.read(telegramChatProvider(123)).failure, isNull);
    },
  );

  test(
    'a delayed library scan or unreadable optional index does not require a manual refresh',
    () async {
      final audio = testAudio();
      final repository = _IndexFailureRepository()
        ..savedAudio = [audio]
        ..page = TelegramAudioPage([audio], 0);
      final container = await setup(repository);
      final library =
          container.read(libraryProvider.notifier) as _SyncingLibrary;
      library.failScan = true;
      repository.failIndexReads = true;
      repository.failIndexWrites = true;
      final downloads = container.read(telegramDownloadsProvider.notifier);
      downloads.enqueue(audio);
      await downloads.waitFor(audio.fileId);
      await _settle();
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        repository.downloadedPath,
      );
      expect(container.read(telegramChatProvider(123)).failure, isNull);
      expect(library.syncCalls, 1);
    },
  );

  test(
    'a real library-provider update upgrades the saved track to its indexed song without a false failure',
    () async {
      final audio = testAudio();
      final repository = _IndexFailureRepository()
        ..savedAudio = [audio]
        ..page = TelegramAudioPage([audio], 0);
      final container = await setup(repository);
      final song = localSong(path: repository.downloadedPath, id: 321);
      (container.read(libraryProvider.notifier) as _SyncingLibrary).nextSong =
          song;
      final downloads = container.read(telegramDownloadsProvider.notifier);
      downloads.enqueue(audio);
      await downloads.waitFor(audio.fileId);
      await _settle();
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
      expect(container.read(telegramChatSongsProvider(123)).single, same(song));
      expect(container.read(telegramChatProvider(123)).failure, isNull);
    },
  );

  test(
    'Retry repairs a previous failed state using music found by a library refresh without downloading again',
    () async {
      final audio = testAudio();
      final repository = _IndexFailureRepository()
        ..savedAudio = [audio]
        ..page = TelegramAudioPage([audio], 0);
      final container = await setup(repository);
      repository.failure = TelegramFailure.generic;
      final manager = container.read(telegramDownloadsProvider.notifier);
      manager.enqueue(audio);
      await manager.waitFor(audio.fileId);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.failed,
      );
      final library =
          container.read(libraryProvider.notifier) as _SyncingLibrary;
      library.nextSong = localSong(path: repository.downloadedPath, id: 321);
      await library.syncNewSongs();
      await _settle();
      manager.resume(audio.fileId);
      await manager.waitFor(audio.fileId);
      await _settle();
      expect(repository.downloadCalls, 1);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.failure,
        isNull,
      );
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        repository.downloadedPath,
      );
    },
  );

  test(
    'an old local lookup failure cannot overwrite successful download availability',
    () async {
      final audio = testAudio();
      final repository = _IndexFailureRepository()
        ..savedAudio = [audio]
        ..page = TelegramAudioPage([audio], 0);
      final files = _DelayedFiles();
      final container = await setup(repository, localFiles: files);
      final staleLookup = Completer<Set<String>>();
      files.nextRead = staleLookup;
      final library =
          container.read(libraryProvider.notifier) as _SyncingLibrary;
      library.nextSong = localSong(path: '/Music/unrelated.mp3');
      await library.syncNewSongs();
      await _settle();
      expect(files.nextRead, isNull);
      final downloads = container.read(telegramDownloadsProvider.notifier);
      downloads.enqueue(audio);
      await downloads.waitFor(audio.fileId);
      await _settle();
      expect(
        container.read(telegramChatSongsProvider(123)).single.path,
        repository.downloadedPath,
      );
      staleLookup.completeError(
        const FileSystemException('Obsolete lookup failed'),
      );
      await _settle();
      expect(container.read(telegramChatProvider(123)).failure, isNull);
      expect(
        container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
        TelegramDownloadPhase.completed,
      );
    },
  );

  for (final removeSource in [false, true]) {
    test(
      removeSource
          ? 'post-publication verification does not depend on a temporary source that has been removed'
          : 'a metadata disk-write failure after publication cannot fail the saved download',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'telegram-publication-',
        );
        addTearDown(() => dir.delete(recursive: true));
        final source = File('${dir.path}/files/music/source.mp3');
        await source.parent.create(recursive: true);
        await source.writeAsBytes([1, 2, 3]);
        final audio = testAudio();
        final index = '${dir.path}/library-v1.json';
        await File(index).writeAsString(
          jsonEncode({
            'files': {'${audio.fileId}': source.path},
            'audio:123': [audio.toJson()],
          }),
        );
        final destination = '${dir.path}/Music/Telegram/song.mp3';
        final repository = TelegramRepositoryImpl(
          cacheDirectory: dir,
          musicPublisher: _PublicationRacePublisher(
            destination,
            indexPath: index,
            removeSource: removeSource,
          ),
        );
        addTearDown(repository.dispose);
        expect(await repository.download(audio), destination);
        expect(await File(destination).readAsBytes(), [1, 2, 3]);
        expect((await repository.loadBindings())[audio.key], destination);
        if (!removeSource) {
          expect(await source.exists(), isTrue);
          await Directory(index).delete();
          await repository.bind(audio.key, destination);
          final reopened = TelegramRepositoryImpl(cacheDirectory: dir);
          addTearDown(reopened.dispose);
          expect(
            (await reopened.cachedAudio(123)).single.localPath,
            destination,
          );
        }
      },
    );
  }
}

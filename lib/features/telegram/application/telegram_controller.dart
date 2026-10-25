import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/providers/library_providers.dart';
import '../../library/application/providers/library_controller.dart';
import '../../library/domain/entities/song.dart';
import '../domain/telegram_local_matcher.dart';
import '../domain/telegram_models.dart';
import '../domain/telegram_repository.dart';
import '../infrastructure/telegram_repository_impl.dart';
import '../infrastructure/telegram_local_files.dart';
import 'telegram_download_controller.dart';
import 'telegram_preferences_controller.dart';
import '../domain/telegram_download.dart';
import 'telegram_artwork_provider.dart';
import '../../player/application/providers/player_controller.dart';

final telegramLocalFilesProvider = Provider<TelegramLocalFiles>(
  (ref) => TelegramLocalFiles(),
);
final telegramLocalMatcherProvider = Provider<TelegramLocalMatcher>(
  (ref) => TelegramLocalMatcher(ref.watch(allSongsProvider)),
);

final telegramLibrarySyncProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    if (!ref.read(libraryProvider).hasValue) return;
    await ref.read(libraryProvider.notifier).syncNewSongs();
  },
);

final telegramRepositoryProvider = Provider<TelegramRepository>((ref) {
  final repository = TelegramRepositoryImpl(
    isInUse: (path) =>
        !ref.mounted ||
        ref.read(playerProvider).songs.any((song) => song.path == path),
  );
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

final telegramProvider = NotifierProvider<TelegramController, TelegramState>(
  TelegramController.new,
);

class TelegramState {
  const TelegramState({
    this.auth = TelegramAuth.disconnected,
    this.chats = const [],
    this.busy = false,
    this.failure,
    this.query = '',
  });
  final TelegramAuth auth;
  final List<TelegramChat> chats;
  final bool busy;
  final TelegramFailure? failure;
  final String query;
  TelegramState copyWith({
    TelegramAuth? auth,
    List<TelegramChat>? chats,
    bool? busy,
    TelegramFailure? failure,
    String? query,
  }) => TelegramState(
    auth: auth ?? this.auth,
    chats: chats ?? this.chats,
    busy: busy ?? this.busy,
    failure: failure,
    query: query ?? this.query,
  );
}

final telegramVisibleChatsProvider = Provider<List<TelegramChat>>((ref) {
  final browse = ref.watch(
    telegramProvider.select((state) => (state.chats, state.query)),
  );
  final query = browse.$2.trim().toLowerCase();
  ref.watch(
    telegramPreferencesProvider.select(
      (value) => (
        Object.hashAll(value['pins'] as List? ?? []),
        Object.hashAll(value['recent'] as List? ?? []),
      ),
    ),
  );
  final preferences = ref.read(telegramPreferencesProvider);
  final pins = (preferences['pins'] as List? ?? []).whereType<int>().toList();
  final recent = (preferences['recent'] as List? ?? [])
      .whereType<int>()
      .toList();
  final result = query.isEmpty
      ? [...browse.$1]
      : browse.$1
            .where((chat) => chat.title.toLowerCase().contains(query))
            .toList();
  final original = {
    for (var i = 0; i < browse.$1.length; i++) browse.$1[i].id: i,
  };
  int rank(int id) => pins.contains(id)
      ? -100 + pins.indexOf(id)
      : recent.contains(id)
      ? recent.indexOf(id) - 50
      : original[id] ?? 0;
  result.sort((a, b) => rank(a.id).compareTo(rank(b.id)));
  return result;
});

final telegramUnassignedProvider = Provider<List<Song>>(
  (ref) => ref
      .watch(allSongsProvider)
      .where((song) => TelegramLocalMatcher.isTelegramPath(song.path))
      .toList(growable: false),
);

class TelegramController extends Notifier<TelegramState> {
  Timer? _search;
  @override
  TelegramState build() {
    final repository = ref.watch(telegramRepositoryProvider);
    final subscription = repository.authorization.listen((auth) {
      if (!ref.mounted) return;
      final previous = state.auth;
      state = state.copyWith(auth: auth);
      if (auth == TelegramAuth.ready && previous != auth) {
        unawaited(_refreshAfterLogin());
      }
    });
    ref.onDispose(() {
      _search?.cancel();
      unawaited(subscription.cancel());
    });
    Future.microtask(() async {
      try {
        final chats = await repository.cachedChats();
        if (ref.mounted && state.chats.isEmpty) {
          state = state.copyWith(chats: chats);
        }
        if (ref.mounted && await repository.hasSession() && ref.mounted) {
          await connect();
        }
      } catch (_) {
        /* The cache is optional; connecting can rebuild it. */
      }
    });
    return const TelegramState();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await action();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          failure: e is TelegramException ? e.failure : TelegramFailure.generic,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false, failure: state.failure);
      }
    }
  }

  Future<void> connect() =>
      _run(() => ref.read(telegramRepositoryProvider).connect());
  Future<void> submit(String value) => _run(() {
    final repository = ref.read(telegramRepositoryProvider);
    return switch (state.auth) {
      TelegramAuth.phone => repository.submitPhone(value),
      TelegramAuth.code => repository.submitCode(value),
      TelegramAuth.password => repository.submitPassword(value),
      _ => Future<void>.value(),
    };
  });
  Future<void> _refreshAfterLogin() async {
    while (ref.mounted && state.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (ref.mounted) await refresh();
  }

  Future<void> refresh({bool more = false}) async {
    if (state.busy) return;
    if (state.auth != TelegramAuth.ready) return;
    await _run(() async {
      final chats = await ref
          .read(telegramRepositoryProvider)
          .chats(more: more);
      if (ref.mounted) state = state.copyWith(chats: chats);
    });
  }

  void search(String value) {
    _search?.cancel();
    _search = Timer(const Duration(milliseconds: 250), () {
      if (ref.mounted) state = state.copyWith(query: value);
    });
  }

  Future<void> logout() => _run(() async {
    final downloads = ref.read(telegramDownloadsProvider.notifier);
    final preferences = ref.read(telegramPreferencesProvider.notifier);
    await Future.wait([downloads.prepareLogout(), preferences.prepareLogout()]);
    try {
      await ref.read(telegramRepositoryProvider).logout();
    } catch (_) {
      downloads.unlock();
      preferences.unlock();
      rethrow;
    }
    if (!ref.mounted) return;
    state = const TelegramState();
    ref.invalidate(telegramChatProvider);
    ref.invalidate(telegramDownloadsProvider);
    ref.invalidate(telegramPreferencesProvider);
    ref.invalidate(telegramArtworkLoaderProvider);
  });
}

class TelegramChatState {
  const TelegramChatState({
    this.tracks = const [],
    this.busy = true,
    this.nextId = 0,
    this.failure,
    this.downloading = const {},
    this.localOnly = true,
    this.query = '',
    this.activeOnly = false,
    this.selected = const {},
    this.sort = 'newest',
  });
  final List<TelegramTrack> tracks;
  final bool busy;
  final int nextId;
  final TelegramFailure? failure;
  final Set<String> downloading;
  final bool localOnly;
  final String query;
  final bool activeOnly;
  final Set<String> selected;
  final String sort;
  TelegramChatState copyWith({
    List<TelegramTrack>? tracks,
    bool? busy,
    int? nextId,
    TelegramFailure? failure,
    Set<String>? downloading,
    bool? localOnly,
    String? query,
    bool? activeOnly,
    Set<String>? selected,
    String? sort,
  }) => TelegramChatState(
    tracks: tracks ?? this.tracks,
    busy: busy ?? this.busy,
    nextId: nextId ?? this.nextId,
    failure: failure,
    downloading: downloading ?? this.downloading,
    localOnly: localOnly ?? this.localOnly,
    query: query ?? this.query,
    activeOnly: activeOnly ?? this.activeOnly,
    selected: selected ?? this.selected,
    sort: sort ?? this.sort,
  );
}

final telegramChatProvider = NotifierProvider.autoDispose
    .family<TelegramChatController, TelegramChatState, int>(
      TelegramChatController.new,
    );
final telegramChatTracksProvider = Provider.autoDispose
    .family<List<TelegramTrack>, int>((ref, id) {
      final state = ref.watch(telegramChatProvider(id));
      final query = state.query.trim().toLowerCase();
      ref.watch(
        telegramDownloadsProvider.select(
          (jobs) => Object.hashAll(
            jobs.entries.where((e) => e.value.unfinished).map((e) => e.key),
          ),
        ),
      );
      final jobs = ref.read(telegramDownloadsProvider);
      final tracks = state.tracks
          .where(
            (e) =>
                (!state.localOnly || e.hasLocalFile) &&
                (!state.activeOnly ||
                    jobs[e.audio.fileId]?.unfinished == true) &&
                (query.isEmpty ||
                    '${e.audio.title} ${e.audio.artist} ${e.audio.fileName}'
                        .toLowerCase()
                        .contains(query)),
          )
          .toList();
      if (state.sort == 'title') {
        tracks.sort(
          (a, b) => a.audio.title.toLowerCase().compareTo(
            b.audio.title.toLowerCase(),
          ),
        );
      }
      if (state.sort == 'oldest') {
        tracks.sort((a, b) => a.audio.messageId.compareTo(b.audio.messageId));
      }
      return tracks;
    });
final telegramChatSongsProvider = Provider.autoDispose.family<List<Song>, int>(
  (ref, id) => ref
      .watch(telegramChatTracksProvider(id))
      .map((e) => e.song)
      .whereType<Song>()
      .toList(growable: false),
);

final telegramLocalMatchCountProvider = Provider.autoDispose.family<int, int>(
  (ref, id) => ref
      .watch(telegramChatProvider(id))
      .tracks
      .where((track) => track.song == null && track.candidates.isNotEmpty)
      .length,
);

final telegramSelectionProvider = Provider.autoDispose
    .family<(List<TelegramTrack>, int), int>((ref, id) {
      final state = ref.watch(telegramChatProvider(id));
      final selected = state.tracks
          .where((e) => state.selected.contains(e.audio.key))
          .toList();
      return (selected, selected.fold<int>(0, (sum, e) => sum + e.audio.size));
    });

final telegramSelectionDetailsProvider = Provider.autoDispose
    .family<
      ({
        List<Song> local,
        List<Song> indexed,
        int remoteCount,
        int remoteBytes,
      }),
      int
    >((ref, id) {
      final selected = ref.watch(telegramSelectionProvider(id)).$1;
      final local = selected.map((e) => e.song).whereType<Song>().toList();
      final remote = selected.where((e) => e.song == null).toList();
      return (
        local: local,
        indexed: local.where((e) => e.id >= 0).toList(),
        remoteCount: remote.length,
        remoteBytes: remote.fold<int>(0, (sum, e) => sum + e.audio.size),
      );
    });

class TelegramChatController extends Notifier<TelegramChatState> {
  TelegramChatController(this.chatId);
  final int chatId;
  List<TelegramAudio> _audio = [];
  int _resolution = 0;
  bool _initialized = false;
  bool _loading = false;
  bool _browseEdited = false;
  Timer? _fileRefresh;
  Timer? _search;

  @override
  TelegramChatState build() {
    final fileSubscription = ref
        .read(telegramRepositoryProvider)
        .fileUpdates
        .listen((file) {
          if (!ref.mounted) return;
          if (file.path.isEmpty && file.received > 0) return;
          var changed = false;
          _audio = _audio
              .map((audio) {
                // A completed cache file is not the completed public download:
                // wait for Music/Telegram publishing before changing this row.
                if (ref
                        .read(telegramDownloadsProvider)[audio.fileId]
                        ?.unfinished ==
                    true) {
                  return audio;
                }
                if (audio.fileId != file.id || audio.localPath == file.path) {
                  return audio;
                }
                changed = true;
                return audio.withLocalPath(file.path);
              })
              .toList(growable: false);
          if (!changed) return;
          _fileRefresh?.cancel();
          _fileRefresh = Timer(const Duration(milliseconds: 80), () {
            if (ref.mounted) unawaited(_resolveSafely());
          });
        });
    ref.onDispose(() {
      _fileRefresh?.cancel();
      _search?.cancel();
      unawaited(fileSubscription.cancel());
    });
    ref.listen(allSongsProvider, (_, _) => unawaited(_resolveSafely()));
    ref.listen(
      telegramDownloadsProvider.select(
        (jobs) => Object.hashAll(
          jobs.values
              .where((job) => job.phase == TelegramDownloadPhase.completed)
              .map((job) => Object.hash(job.audio.fileId, job.path)),
        ),
      ),
      (_, _) => unawaited(_resolveSafely()),
    );
    ref.listen(telegramProvider.select((s) => s.auth), (_, auth) {
      if (_initialized && auth == TelegramAuth.ready) unawaited(refresh());
    });
    Future.microtask(_initialize);
    final saved = ref.read(telegramPreferencesProvider.notifier).chat(chatId);
    return TelegramChatState(
      localOnly: saved['localOnly'] as bool? ?? true,
      query: saved['query'] as String? ?? '',
      sort: saved['sort'] as String? ?? 'newest',
    );
  }

  Future<void> _initialize() async {
    try {
      final preferences = ref.read(telegramPreferencesProvider.notifier);
      await preferences.ready;
      if (!ref.mounted) return;
      if (!_browseEdited) {
        final saved = preferences.chat(chatId);
        state = state.copyWith(
          localOnly: saved['localOnly'] as bool? ?? true,
          query: saved['query'] as String? ?? '',
          sort: saved['sort'] as String? ?? 'newest',
        );
      }
      _audio = await ref.read(telegramRepositoryProvider).cachedAudio(chatId);
      if (!ref.mounted) return;
      await _resolve();
      if (!ref.mounted) return;
      _initialized = true;
      if (ref.read(telegramProvider).auth == TelegramAuth.ready) {
        await refresh();
      } else {
        state = state.copyWith(busy: false);
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(busy: false, failure: TelegramFailure.generic);
      }
    }
  }

  Future<void> _resolveSafely() async {
    try {
      await _resolve();
    } catch (_) {
      if (ref.mounted) state = state.copyWith(failure: TelegramFailure.generic);
    }
  }

  Future<void> _resolve() async {
    final generation = ++_resolution;
    final repository = ref.read(telegramRepositoryProvider);
    final matcher = ref.read(telegramLocalMatcherProvider);
    final bindings = await repository.loadBindings();
    final paths = {
      ..._audio.map((e) => bindings[e.key]).whereType<String>(),
      ..._audio.map((e) => e.localPath),
      for (final audio in _audio)
        ...matcher.candidatesFor(audio).map((song) => song.path),
    }..remove('');
    final existing = await ref
        .read(telegramLocalFilesProvider)
        .existingPaths(paths);
    if (!ref.mounted || generation != _resolution) return;
    final jobs = ref.read(telegramDownloadsProvider);
    state = state.copyWith(
      tracks: _audio
          .map(
            (e) => matcher.resolve(
              jobs[e.fileId]?.unfinished == true ? e.withLocalPath('') : e,
              bindings,
              existing,
            ),
          )
          .toList(),
    );
  }

  Future<void> refresh({bool more = false}) async {
    if (!ref.mounted || ref.read(telegramProvider).auth != TelegramAuth.ready) {
      return;
    }
    if (_loading) return;
    if (more && (state.busy || state.nextId == 0)) return;
    _loading = true;
    state = state.copyWith(busy: true);
    try {
      final page = await ref
          .read(telegramRepositoryProvider)
          .audio(chatId, fromId: more ? state.nextId : 0);
      if (!ref.mounted) return;
      _audio = {
        for (final audio in [..._audio, ...page.items]) audio.key: audio,
      }.values.toList()..sort((a, b) => b.messageId.compareTo(a.messageId));
      state = state.copyWith(nextId: page.nextId);
      await _resolve();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          failure: e is TelegramException ? e.failure : TelegramFailure.generic,
        );
      }
    } finally {
      _loading = false;
      if (ref.mounted) {
        state = state.copyWith(busy: false, failure: state.failure);
      }
    }
  }

  void setLocalOnly(bool value) {
    _browseEdited = true;
    state = state.copyWith(localOnly: value, activeOnly: false);
    ref.read(telegramPreferencesProvider.notifier).updateChat(chatId, {
      'localOnly': value,
    });
  }

  void setActiveOnly() {
    _browseEdited = true;
    state = state.copyWith(localOnly: false, activeOnly: true);
  }

  void search(String value) {
    _browseEdited = true;
    _search?.cancel();
    _search = Timer(const Duration(milliseconds: 250), () {
      if (!ref.mounted) return;
      state = state.copyWith(query: value);
      ref.read(telegramPreferencesProvider.notifier).updateChat(chatId, {
        'query': value,
      });
    });
  }

  void setSort(String value) {
    _browseEdited = true;
    state = state.copyWith(sort: value);
    ref.read(telegramPreferencesProvider.notifier).updateChat(chatId, {
      'sort': value,
    });
  }

  void toggleSelection(String key) {
    final selected = {...state.selected};
    if (!selected.remove(key)) selected.add(key);
    state = state.copyWith(selected: selected);
  }

  void clearSelection() => state = state.copyWith(selected: {});

  Future<void> bind(TelegramAudio audio, Song song) async {
    try {
      final existing = await ref.read(telegramLocalFilesProvider).existingPaths(
        [song.path],
      );
      if (!existing.contains(song.path)) {
        throw const TelegramException(TelegramFailure.generic);
      }
      await ref.read(telegramRepositoryProvider).bind(audio.key, song.path);
      if (ref.mounted) await _resolve();
    } catch (_) {
      if (ref.mounted) state = state.copyWith(failure: TelegramFailure.generic);
    }
  }

  Future<void> download(TelegramAudio audio) async {
    if (ref.read(telegramDownloadsProvider)[audio.fileId]?.unfinished == true) {
      return;
    }
    final manager = ref.read(telegramDownloadsProvider.notifier);
    if (!manager.enqueue(audio)) return;
    await manager.waitFor(audio.fileId);
    if (!ref.mounted) return;
    final job = ref.read(telegramDownloadsProvider)[audio.fileId];
    await _resolveSafely();
    if (ref.mounted && job?.failure != null) {
      state = state.copyWith(failure: job!.failure);
    }
  }
}

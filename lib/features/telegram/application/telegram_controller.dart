import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/providers/library_providers.dart';
import '../../library/domain/entities/song.dart';
import '../domain/telegram_local_matcher.dart';
import '../domain/telegram_models.dart';
import '../domain/telegram_repository.dart';
import '../infrastructure/telegram_repository_impl.dart';
import '../infrastructure/telegram_local_files.dart';

final telegramLocalFilesProvider = Provider<TelegramLocalFiles>(
  (ref) => TelegramLocalFiles(),
);

final telegramRepositoryProvider = Provider<TelegramRepository>((ref) {
  final repository = TelegramRepositoryImpl();
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
  final state = ref.watch(telegramProvider);
  final query = state.query.trim().toLowerCase();
  return query.isEmpty
      ? state.chats
      : state.chats
            .where((chat) => chat.title.toLowerCase().contains(query))
            .toList();
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
    await ref.read(telegramRepositoryProvider).logout();
    if (!ref.mounted) return;
    state = const TelegramState();
    ref.invalidate(telegramChatProvider);
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
  });
  final List<TelegramTrack> tracks;
  final bool busy;
  final int nextId;
  final TelegramFailure? failure;
  final Set<String> downloading;
  final bool localOnly;
  TelegramChatState copyWith({
    List<TelegramTrack>? tracks,
    bool? busy,
    int? nextId,
    TelegramFailure? failure,
    Set<String>? downloading,
    bool? localOnly,
  }) => TelegramChatState(
    tracks: tracks ?? this.tracks,
    busy: busy ?? this.busy,
    nextId: nextId ?? this.nextId,
    failure: failure,
    downloading: downloading ?? this.downloading,
    localOnly: localOnly ?? this.localOnly,
  );
}

final telegramChatProvider = NotifierProvider.autoDispose
    .family<TelegramChatController, TelegramChatState, int>(
      TelegramChatController.new,
    );
final telegramChatTracksProvider = Provider.autoDispose
    .family<List<TelegramTrack>, int>((ref, id) {
      final state = ref.watch(telegramChatProvider(id));
      return state.localOnly
          ? state.tracks.where((e) => e.song != null).toList(growable: false)
          : state.tracks;
    });
final telegramChatSongsProvider = Provider.autoDispose.family<List<Song>, int>(
  (ref, id) => ref
      .watch(telegramChatProvider(id))
      .tracks
      .map((e) => e.song)
      .whereType<Song>()
      .toList(growable: false),
);

class TelegramChatController extends Notifier<TelegramChatState> {
  TelegramChatController(this.chatId);
  final int chatId;
  List<TelegramAudio> _audio = [];
  int _resolution = 0;
  bool _initialized = false;
  bool _loading = false;

  @override
  TelegramChatState build() {
    ref.listen(allSongsProvider, (_, _) => unawaited(_resolveSafely()));
    ref.listen(telegramProvider.select((s) => s.auth), (_, auth) {
      if (_initialized && auth == TelegramAuth.ready) unawaited(refresh());
    });
    Future.microtask(_initialize);
    return const TelegramChatState();
  }

  Future<void> _initialize() async {
    try {
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
    final matcher = TelegramLocalMatcher(ref.read(allSongsProvider));
    final bindings = await repository.loadBindings();
    final paths = {
      ..._audio.map((e) => bindings[e.key]).whereType<String>(),
      ..._audio.map((e) => e.localPath),
    }..remove('');
    final existing = await ref
        .read(telegramLocalFilesProvider)
        .existingPaths(paths);
    if (!ref.mounted || generation != _resolution) return;
    state = state.copyWith(
      tracks: _audio
          .map((e) => matcher.resolve(e, bindings, existing))
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

  void setLocalOnly(bool value) => state = state.copyWith(localOnly: value);

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
    if (state.downloading.contains(audio.key)) return;
    // Keep this controller alive until the operation finishes when navigating back.
    final keepAlive = ref.keepAlive();
    state = state.copyWith(downloading: {...state.downloading, audio.key});
    try {
      final repository = ref.read(telegramRepositoryProvider);
      final path = await repository.download(audio.fileId);
      await repository.bind(audio.key, path);
      if (ref.mounted) await _resolve();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          failure: e is TelegramException ? e.failure : TelegramFailure.generic,
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          downloading: {...state.downloading}..remove(audio.key),
          failure: state.failure,
        );
      }
      keepAlive.close();
    }
  }
}

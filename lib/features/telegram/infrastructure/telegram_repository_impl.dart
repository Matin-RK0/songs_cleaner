import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'telegram_cache_store.dart';

import '../domain/telegram_models.dart';
import '../domain/telegram_repository.dart';
import '../domain/telegram_message_link.dart';
import '../domain/telegram_connection_policy.dart';
import 'tdlib_transport.dart';
import 'telegram_audio_mapper.dart';
import 'telegram_chat_mapper.dart';
import 'telegram_music_publisher.dart';
import 'telegram_diagnostics.dart';
import '../domain/telegram_download.dart';

class TelegramRepositoryImpl implements TelegramRepository {
  TelegramRepositoryImpl({
    Directory? cacheDirectory,
    TelegramMusicPublisher? musicPublisher,
    bool Function(String)? isInUse,
    TdlibTransport Function()? transportFactory,
  }) : _directory = cacheDirectory,
       _transport = transportFactory?.call(),
       _musicPublisher = musicPublisher ?? TelegramMusicPublisher(),
       _isInUse = isInUse ?? ((_) => false) {
    final transport = _transport;
    if (transport != null) _listenTransport(transport);
  }

  final TelegramMusicPublisher _musicPublisher;
  final bool Function(String) _isInUse;
  bool _migratingCopies = false;
  final _downloads = <int, Future<String>>{};
  final _epochs = <int, int>{};
  final _progress = <int, void Function(TelegramTransferProgress)>{};
  final _completedFiles = <int, Completer<String>>{};
  final _savingAudio = <int>{};
  final _committedAudio = <int, String>{};
  final _messageOpens = <String, Future<bool>>{};

  static const apiId = int.fromEnvironment('TELEGRAM_API_ID');
  static const apiHash = String.fromEnvironment('TELEGRAM_API_HASH');
  final _auth = StreamController<TelegramAuth>.broadcast();
  final _connection = StreamController<TelegramConnection>.broadcast();
  final _files = StreamController<TelegramLocalFile>.broadcast();
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'songs_cleaner_telegram'),
  );
  TdlibTransport? _transport;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  late final _cache = TelegramCacheStore(_dir);
  int _imageDownloads = 0;
  int _artworkEpoch = 0;
  Future<void>? _cacheClearing;
  final _coverRequests = <int>{};
  int _chatLimit = 50;
  final _loadedChatIds = <int>{};
  final _browseVersions = <String, int>{};
  bool _initializing = false;
  Future<void>? _readyPreparation;
  Future<void>? _maintenance;
  DateTime? _lastNetworkRetry;
  TelegramConnection _connectionState = TelegramConnection.unknown;
  int _sessionEpoch = 0;
  int _connectVersion = 0;
  Future<void>? _connecting;
  Future<void>? _transportStarting;
  bool _disposed = false;
  String? _key;
  Directory? _directory;
  TelegramAuth _state = TelegramAuth.disconnected;

  @override
  Stream<TelegramAuth> get authorization => _auth.stream;
  @override
  Stream<TelegramConnection> get connection => _connection.stream;
  @override
  Stream<TelegramLocalFile> get fileUpdates => _files.stream;
  @override
  Future<bool> hasSession() async =>
      await _secure.read(key: 'telegram.session.active') == 'true';
  void _emit(TelegramAuth state) {
    _state = state;
    if (!_auth.isClosed) _auth.add(state);
    if (state == TelegramAuth.disconnected) {
      _emitConnection(TelegramConnection.closed);
    }
  }

  void _emitConnection(TelegramConnection value) {
    if (_connectionState == value || _disposed) return;
    _connectionState = value;
    if (value.unavailable) {
      for (final scope in _browseVersions.keys.toList()) {
        _browseVersions[scope] = _browseVersions[scope]! + 1;
        _transport?.cancelReads(scope);
      }
    }
    if (!_connection.isClosed) _connection.add(value);
  }

  void _listenTransport(TdlibTransport transport, [Directory? directory]) {
    _subscription = transport.updates.listen((update) {
      if (_transport != transport || _disposed) return;
      if (update['@type'] == 'updateConnectionState') {
        _emitConnection(switch ((update['state'] as Map?)?['@type']) {
          'connectionStateReady' => TelegramConnection.ready,
          'connectionStateWaitingForNetwork' =>
            TelegramConnection.waitingForNetwork,
          'connectionStateUpdating' => TelegramConnection.updating,
          'connectionStateClosed' => TelegramConnection.closed,
          _ => TelegramConnection.connecting,
        });
      } else if (update['@type'] == 'updateFile' && !_files.isClosed) {
        _acceptFile(update['file'] as Map<String, dynamic>);
      } else if (update['@type'] == 'updateAuthorizationState') {
        unawaited(
          () async {
            final dir = directory ?? await _dir();
            if (_transport != transport || _disposed) return;
            await _authorization(
              update['authorization_state'] as Map<String, dynamic>,
              dir,
            );
          }().catchError((Object error, StackTrace stackTrace) {
            if (_transport != transport || _disposed) return;
            TelegramDiagnostics.report(
              'Restoring Telegram authorization',
              error,
              stackTrace,
            );
            _emit(TelegramAuth.disconnected);
          }),
        );
      }
    });
  }

  @override
  Future<void> retryConnection() async {
    final transport = _transport;
    if (transport == null || _connectionState == TelegramConnection.closed) {
      if (transport != null) {
        await _subscription?.cancel();
        await transport.dispose();
        _transport = null;
        _emit(TelegramAuth.disconnected);
      }
      await connect();
      return;
    }
    if (!_connectionState.unavailable) return;
    final now = DateTime.now();
    if (_lastNetworkRetry != null &&
        now.difference(_lastNetworkRetry!) <
            TelegramConnectionPolicy.retryCooldown) {
      return;
    }
    _lastNetworkRetry = now;
    const scope = 'network-recovery';
    transport.cancelReads(scope);
    try {
      // TDLib has no Android connectivity integration in this worker. Send both
      // local commands in order before awaiting replies, so even a timeout
      // cannot leave networking disabled. This preserves auth and file transfers.
      await Future.wait([
        transport.read(scope, 'setNetworkType', {
          'type': {'@type': 'networkTypeNone'},
        }),
        transport.read(scope, 'setNetworkType', {
          'type': {'@type': 'networkTypeOther'},
        }),
      ]).timeout(TelegramConnectionPolicy.retryTimeout);
    } catch (_) {
      transport.cancelReads(scope);
      rethrow;
    }
  }

  Future<Directory> _dir() async => _directory ??= await Directory(
    '${(await getApplicationSupportDirectory()).path}/telegram',
  ).create(recursive: true);

  Future<Map<String, dynamic>> _store() => _cache.load();
  Future<void> _save() => _cache.save();

  @override
  Future<void> connect() async {
    // Database/key setup must remain single-flight even if Retry is tapped
    // before the transport has been created.
    if (_transport == null && _connecting != null) return _connecting!;
    final connecting = _connect();
    final version = _connectVersion;
    final pending = connecting.timeout(
      TelegramConnectionPolicy.operationTimeout,
      onTimeout: () {
        if (version == _connectVersion && !_disposed) {
          ++_connectVersion;
          _emit(TelegramAuth.disconnected);
        }
        throw const TelegramException(TelegramFailure.network);
      },
    );
    _connecting = pending;
    try {
      await pending;
    } finally {
      if (identical(_connecting, pending)) _connecting = null;
    }
  }

  Future<void> _connect() async {
    final version = ++_connectVersion;
    if (!Platform.isAndroid) {
      _emit(TelegramAuth.unsupported);
      return;
    }
    if (apiId <= 0 || apiHash.isEmpty) {
      _emit(TelegramAuth.unconfigured);
      return;
    }
    if (_transport != null) {
      if (_state != TelegramAuth.disconnected) {
        // Probe the live client rather than replaying a possibly stale starting
        // state. TDLib owns reconnecting its existing session.
        final transport = _td;
        try {
          await _transportStarting;
          if (version != _connectVersion || _disposed) return;
          transport.cancelReads('authorization');
          final initial = await transport.read(
            'authorization',
            'getAuthorizationState',
          );
          if (version != _connectVersion || _disposed) return;
          await _authorization(initial, await _dir());
        } catch (_) {
          if (version == _connectVersion && !_disposed) {
            await _subscription?.cancel();
            _transport = null;
            await transport.dispose();
            _emit(TelegramAuth.disconnected);
          }
          rethrow;
        }
        return;
      }
      await _subscription?.cancel();
      await _transport?.dispose();
      _transport = null;
    }
    _emit(TelegramAuth.starting);
    _readyPreparation = null;
    try {
      final dir = await _dir();
      if (version != _connectVersion || _disposed) return;
      _key = await _secure.read(key: 'telegram.database.key');
      if (version != _connectVersion || _disposed) return;
      if (_key == null) {
        final random = Random.secure();
        _key = base64Encode(List.generate(32, (_) => random.nextInt(256)));
        await _secure.write(key: 'telegram.database.key', value: _key);
      }
      if (version != _connectVersion || _disposed) return;
      final transport = _transport = TdlibTransport();
      _listenTransport(transport, dir);
      await (_transportStarting = transport.start());
      if (version != _connectVersion || _disposed) return;
      final initial = await transport.read(
        'authorization',
        'getAuthorizationState',
      );
      if (version != _connectVersion || _disposed) return;
      await _authorization(initial, dir);
    } catch (_) {
      if (version != _connectVersion || _disposed) rethrow;
      await _subscription?.cancel();
      await _transport?.dispose();
      _transport = null;
      _emit(TelegramAuth.disconnected);
      rethrow;
    }
  }

  Future<void> _authorization(Map<String, dynamic> state, Directory dir) async {
    if (_disposed) return;
    final type = state['@type'];
    if (type == 'authorizationStateWaitTdlibParameters') {
      if (_initializing) return;
      _initializing = true;
      try {
        await _transport!.call('setTdlibParameters', {
          'use_test_dc': false,
          'database_directory': '${dir.path}/db',
          'files_directory': '${dir.path}/files',
          'database_encryption_key': _key,
          'use_file_database': true,
          'use_chat_info_database': true,
          'use_message_database': true,
          'use_secret_chats': false,
          'api_id': apiId,
          'api_hash': apiHash,
          'system_language_code': Platform.localeName.split('_').first,
          'device_model': 'Songs Cleaner Android',
          'system_version': '',
          'application_version': '0.1.0',
        });
      } catch (_) {
        // Drop the failed transport so the next Connect starts a fresh client.
        final failed = _transport;
        _transport = null;
        await failed?.dispose();
        _emit(TelegramAuth.disconnected);
      } finally {
        _initializing = false;
      }
      return;
    }
    if (type == 'authorizationStateReady') {
      await (_readyPreparation ??= _prepareReady());
    }
    _emit(switch (type) {
      'authorizationStateWaitPhoneNumber' => TelegramAuth.phone,
      'authorizationStateWaitCode' => TelegramAuth.code,
      'authorizationStateWaitPassword' => TelegramAuth.password,
      'authorizationStateReady' => TelegramAuth.ready,
      'authorizationStateClosed' ||
      'authorizationStateLoggingOut' => TelegramAuth.disconnected,
      'authorizationStateClosing' => TelegramAuth.starting,
      _ => TelegramAuth.other,
    });
    if (type == 'authorizationStateReady' && _maintenance == null) {
      final maintenance = _maintainStorage();
      _maintenance = maintenance;
      unawaited(
        maintenance.whenComplete(() {
          if (identical(_maintenance, maintenance)) _maintenance = null;
        }),
      );
    }
  }

  TdlibTransport get _td =>
      _transport ?? (throw const TelegramException(TelegramFailure.network));

  Future<void> _prepareReady() async {
    await _secure.write(key: 'telegram.session.active', value: 'true');
  }

  Future<void> _maintainStorage() async {
    final session = _sessionEpoch;
    try {
      await _pruneTemporary();
      if (_disposed || session != _sessionEpoch) return;
      final store = await _store();
      if (store['imagePurgePending'] == true) {
        try {
          await _purgeImageStorage();
          store.remove('imagePurgePending');
          await _save();
        } catch (_) {
          // Keep the durable cleanup request for the next connection.
        }
      }
      unawaited(_trimImageCache());
      await _cleanPublishedCopies();
    } catch (error, stackTrace) {
      TelegramDiagnostics.report(
        'Maintaining Telegram storage',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> submitPhone(String phone) async {
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone.trim())) {
      throw const TelegramException(TelegramFailure.phone);
    }
    await _td.call('setAuthenticationPhoneNumber', {
      'phone_number': phone.trim(),
    });
  }

  @override
  Future<void> submitCode(String code) async {
    if (code.trim().isEmpty) {
      throw const TelegramException(TelegramFailure.code);
    }
    await _td.call('checkAuthenticationCode', {'code': code.trim()});
  }

  @override
  Future<void> submitPassword(String password) async {
    await _td.call('checkAuthenticationPassword', {'password': password});
  }

  @override
  Future<List<TelegramChat>> chats({bool more = false}) =>
      _browse('chats', (version, session) => _chats(more, version, session));

  Future<List<TelegramChat>> _chats(bool more, int version, int session) async {
    const scope = 'chats';
    void check() => _checkBrowse(scope, version, session);
    Future<Map<String, dynamic>> read(
      String type,
      Map<String, dynamic> fields,
    ) async {
      check();
      final result = await _td.read(scope, type, fields);
      check();
      return result;
    }

    final limit = more ? _chatLimit + 50 : 50;
    final loaded = more ? {..._loadedChatIds} : <int>{};
    final previous = {for (final chat in await cachedChats()) chat.id: chat};
    for (final list in ['chatListMain', 'chatListArchive']) {
      try {
        await read('loadChats', {
          'chat_list': {'@type': list},
          'limit': 50,
        });
      } on TelegramException catch (e) {
        // TDLib uses 404 when the complete chat list has already been loaded.
        if (e.failure != TelegramFailure.generic) rethrow;
      }
    }
    final result = <TelegramChat>[];
    final seen = <int>{};
    for (final list in ['chatListMain', 'chatListArchive']) {
      final page = await read('getChats', {
        'chat_list': {'@type': list},
        'limit': limit,
      });
      for (final id in page['chat_ids'] as List? ?? []) {
        if (!seen.add(id as int)) continue;
        if (more && loaded.contains(id) && previous[id] != null) {
          result.add(previous[id]!);
          continue;
        }
        final chat = await read('getChat', {'chat_id': id});
        result.add(TelegramChatMapper.fromJson(chat));
        loaded.add(id);
      }
    }
    final preferences = await loadPreferences();
    final quick = {
      ...(preferences['pins'] as List? ?? []).whereType<int>(),
      ...(preferences['recent'] as List? ?? []).whereType<int>(),
    };
    for (final id in quick) {
      if (!seen.add(id) || previous[id] == null) continue;
      try {
        result.add(
          TelegramChatMapper.fromJson(await read('getChat', {'chat_id': id})),
        );
        loaded.add(id);
      } catch (_) {
        result.add(previous[id]!);
      }
    }
    final store = await _store();
    check();
    _chatLimit = limit;
    _loadedChatIds
      ..clear()
      ..addAll(loaded);
    store['chats'] = result.map((e) => e.toJson()).toList();
    await _save();
    return result;
  }

  int _beginBrowse(String scope) {
    final version = (_browseVersions[scope] ?? 0) + 1;
    _browseVersions[scope] = version;
    _td.cancelReads(scope);
    return version;
  }

  Future<T> _browse<T>(
    String scope,
    Future<T> Function(int version, int session) action,
  ) {
    if (_cacheClearing != null) {
      return Future.error(const TelegramException(TelegramFailure.network));
    }
    final version = _beginBrowse(scope);
    return action(version, _sessionEpoch).timeout(
      const Duration(seconds: 18),
      onTimeout: () {
        if (_browseVersions[scope] == version) {
          _browseVersions[scope] = version + 1;
          _transport?.cancelReads(scope);
        }
        throw const TelegramException(TelegramFailure.network);
      },
    );
  }

  void _checkBrowse(String scope, int version, int session) {
    if (_disposed ||
        session != _sessionEpoch ||
        _browseVersions[scope] != version) {
      throw const TelegramException(TelegramFailure.network);
    }
  }

  @override
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0}) => _browse(
    'audio:$chatId',
    (version, session) => _audio(chatId, fromId, version, session),
  );

  Future<TelegramAudioPage> _audio(
    int chatId,
    int fromId,
    int version,
    int session,
  ) async {
    final scope = 'audio:$chatId';
    final response = await _td.read(scope, 'searchChatMessages', {
      'chat_id': chatId,
      'query': '',
      'from_message_id': fromId,
      'offset': 0,
      'limit': 50,
      'filter': {'@type': 'searchMessagesFilterAudio'},
      'message_thread_id': 0,
      'saved_messages_topic_id': 0,
    });
    final items = <TelegramAudio>[];
    for (final value in response['messages'] as List? ?? []) {
      final audio = TelegramAudioMapper.fromMessage(
        value as Map<String, dynamic>,
        chatId,
      );
      if (audio != null) items.add(audio);
    }
    final store = await _store();
    // Refreshing the newest page must not evict older offline music.
    final previous = await cachedAudio(chatId);
    final merged = {
      for (final audio in [...previous, ...items]) audio.key: audio,
    };
    _checkBrowse(scope, version, session);
    store['audio:$chatId'] = merged.values.map((e) => e.toJson()).toList();
    await _save();
    return TelegramAudioPage(
      items,
      (response['next_from_message_id'] as int?) ?? 0,
    );
  }

  @override
  Future<String> download(
    TelegramAudio audio, {
    void Function(TelegramTransferProgress)? onProgress,
  }) async {
    final pending = _downloads[audio.fileId];
    if (pending != null) return pending;
    final epoch = (_epochs[audio.fileId] ?? 0) + 1;
    _epochs[audio.fileId] = epoch;
    if (onProgress != null) _progress[audio.fileId] = onProgress;
    final future = _download(audio, epoch);
    _downloads[audio.fileId] = future;
    try {
      return await future;
    } catch (error, stackTrace) {
      TelegramDiagnostics.report(
        'Receiving or publishing Telegram audio',
        error,
        stackTrace,
      );
      if (_epochs[audio.fileId] == epoch && !_disposed) {
        try {
          await cancelDownload(audio.fileId, discard: true);
        } catch (_) {}
      }
      rethrow;
    } finally {
      _downloads.remove(audio.fileId);
      _progress.remove(audio.fileId);
      _completedFiles.remove(audio.fileId);
      _epochs.remove(audio.fileId);
      _savingAudio.remove(audio.fileId);
    }
  }

  void _acceptFile(Map<String, dynamic> file) {
    final id = file['id'] as int;
    final local = file['local'] as Map? ?? {};
    final path = TelegramAudioMapper.completedPath(file);
    final received = local['downloaded_size'] as int? ?? 0;
    final total = file['size'] as int? ?? 0;
    _files.add(TelegramLocalFile(id, path, received: received, total: total));
    if (!_savingAudio.contains(id)) {
      _progress[id]?.call(
        TelegramTransferProgress(received: received, total: total),
      );
    }
    final completion = _completedFiles[id];
    if (path.isNotEmpty && completion != null && !completion.isCompleted) {
      completion.complete(path);
    }
  }

  void _checkEpoch(int id, int epoch) {
    if (_disposed || _epochs[id] != epoch) {
      throw const TelegramTransferInterrupted();
    }
  }

  Future<String> _download(TelegramAudio audio, int epoch) async {
    final fileId = audio.fileId;
    final store = await _store();
    final published =
        _committedAudio[fileId] ??
        TelegramCacheStore.paths(store['publishedFiles'])['$fileId'];
    if (published != null && await File(published).exists()) return published;
    await _musicPublisher.ensureAccess();
    _checkEpoch(fileId, epoch);
    final cached = TelegramCacheStore.paths(store['files'])['$fileId'];
    if (cached != null && await File(cached).exists()) {
      return _publishDownload(cached, audio, epoch);
    }
    // Register before sending: a cached/native completion can arrive immediately.
    final completion = Completer<String>();
    _completedFiles[fileId] = completion;
    final completed = completion.future;
    unawaited(completed.then<void>((_) {}, onError: (Object _) {}));
    final storeAudio = Map<String, dynamic>.from(
      store['temporaryAudio'] as Map? ?? {},
    );
    storeAudio['$fileId'] = audio.toJson();
    store['temporaryAudio'] = storeAudio;
    await _save();
    _checkEpoch(fileId, epoch);
    final first = await _td.call('downloadFile', {
      'file_id': fileId,
      'priority': 16,
      'offset': 0,
      'limit': 0,
      'synchronous': false,
    });
    _checkEpoch(fileId, epoch);
    _acceptFile(first);
    // Events drive progress; a slow watchdog only repairs missed updates.
    final watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_epochs[fileId] != epoch || completion.isCompleted) return;
      unawaited(
        _td
            .call('getFile', {'file_id': fileId})
            .then((file) {
              if (!_disposed) _acceptFile(file);
            })
            .catchError((Object _) {}),
      );
    });
    try {
      final path = await completed.timeout(const Duration(minutes: 10));
      _checkEpoch(fileId, epoch);
      return await _publishDownload(path, audio, epoch);
    } on TimeoutException {
      await cancelDownload(fileId, discard: true);
      throw const TelegramException(TelegramFailure.network);
    } finally {
      watchdog.cancel();
    }
  }

  @override
  Future<void> cancelDownload(int fileId, {bool discard = false}) async {
    if (_epochs.containsKey(fileId)) _epochs[fileId] = _epochs[fileId]! + 1;
    final completion = _completedFiles[fileId];
    if (completion != null && !completion.isCompleted) {
      completion.completeError(const TelegramTransferInterrupted());
    }
    if (_transport != null) {
      await _td.call('cancelDownloadFile', {
        'file_id': fileId,
        'only_if_pending': false,
      });
      if (discard) await _discardTemporary(fileId);
    }
    if (discard) {
      final staged =
          ((await _store())['temporaryAudio'] as Map?)?['$fileId'] as Map?;
      final source = staged?['localPath'] as String?;
      if (source != null && source.isNotEmpty) await _removePrivateCopy(source);
    }
  }

  Future<void> _discardTemporary(int id) async {
    // TDLib owns only its private copy; this never deletes a public file path.
    if (_transport == null) return;
    final transport = _td;
    final session = _sessionEpoch;
    await transport.call('deleteFile', {'file_id': id});
    if (_disposed || session != _sessionEpoch || transport != _transport) {
      return;
    }
    final store = await _store();
    final staged = Map<String, dynamic>.from(
      store['temporaryAudio'] as Map? ?? {},
    )..remove('$id');
    store['temporaryAudio'] = staged;
    await _save();
  }

  Future<void> _pruneTemporary() async {
    final session = _sessionEpoch;
    final transport = _transport;
    final staged = Map<String, dynamic>.from(
      (await _store())['temporaryAudio'] as Map? ?? {},
    );
    for (final key in staged.keys) {
      if (_disposed || session != _sessionEpoch || transport != _transport) {
        return;
      }
      final id = int.tryParse(key);
      if (id == null || _downloads.containsKey(id)) continue;
      try {
        await _discardTemporary(id);
      } catch (_) {
        /* Retry on next connection. */
      }
    }
  }

  Future<void> _cleanPublishedCopies() async {
    if (_migratingCopies || _disposed) return;
    _migratingCopies = true;
    try {
      final published = TelegramCacheStore.paths(
        (await _store())['publishedFiles'],
      );
      final root = await (await _dir()).resolveSymbolicLinks();
      final prefix =
          '$root${Platform.pathSeparator}files${Platform.pathSeparator}';
      for (final entry in published.entries) {
        if (_disposed || _transport == null) return;
        final id = int.tryParse(entry.key);
        if (id == null || _downloads.containsKey(id)) continue;
        try {
          final public = File(entry.value);
          if (!await public.exists()) continue;
          final native = await _td.call('getFile', {'file_id': id});
          final sourcePath = TelegramAudioMapper.completedPath(native);
          if (sourcePath.isEmpty || _disposed || _isInUse(sourcePath)) continue;
          final source = File(sourcePath);
          if (!await source.exists() ||
              !(await source.resolveSymbolicLinks()).startsWith(prefix)) {
            continue;
          }
          if (await source.length() != await public.length()) continue;
          // Upgrade cleanup: older releases published the public copy but left
          // its complete TDLib duplicate behind. Never delete the sole copy.
          await _td.call('deleteFile', {'file_id': id});
        } catch (_) {
          /* A missing/active legacy copy can be retried next session. */
        }
      }
    } finally {
      _migratingCopies = false;
    }
  }

  Future<String> _publishDownload(
    String sourcePath,
    TelegramAudio audio,
    int epoch,
  ) async {
    _checkEpoch(audio.fileId, epoch);
    _savingAudio.add(audio.fileId);
    _progress[audio.fileId]?.call(
      TelegramTransferProgress(
        received: audio.size,
        total: audio.size,
        saving: true,
      ),
    );
    final stagedStore = await _store();
    final staged = Map<String, dynamic>.from(
      stagedStore['temporaryAudio'] as Map? ?? {},
    );
    staged['${audio.fileId}'] = audio.withLocalPath(sourcePath).toJson();
    stagedStore['temporaryAudio'] = staged;
    await _save();
    final path = await _musicPublisher.publish(sourcePath, audio);
    // Native storage verifies the copy before publishing it. Its successful
    // reply is the commit boundary: re-statting the shared path from Dart can
    // fail under scoped storage even though MediaStore saved the file correctly.
    _committedAudio[audio.fileId] = path;
    try {
      await _indexPublishedAudio(audio, path);
      try {
        await _discardTemporary(audio.fileId);
      } catch (error, stackTrace) {
        TelegramDiagnostics.report(
          'Cleaning a committed audio transfer',
          error,
          stackTrace,
        );
      }
      await _removePrivateCopy(sourcePath);
    } catch (error, stackTrace) {
      // Keep the source/cleanup record if indexing is not yet durable. Neither
      // old cache parsing nor optional cleanup can fail a verified public file.
      TelegramDiagnostics.report(
        'Indexing a verified public audio file',
        error,
        stackTrace,
      );
    }
    return path;
  }

  Future<void> _indexPublishedAudio(TelegramAudio audio, String path) async {
    final store = await _store();
    final paths = TelegramCacheStore.paths(store['files']);
    final published = TelegramCacheStore.paths(store['publishedFiles']);
    final bindings = TelegramCacheStore.paths(store['bindings']);
    paths['${audio.fileId}'] = path;
    published['${audio.fileId}'] = path;
    // Linking an existing record only needs its IDs. Do not decode unrelated
    // cached titles/durations/cover data while committing a completed download.
    for (final entry in store.entries) {
      if (!entry.key.startsWith('audio:') || entry.value is! List) continue;
      for (final value in entry.value as List) {
        if (value is! Map || value['fileId'] != audio.fileId) continue;
        final chat = value['chatId'];
        final message = value['messageId'];
        if (chat is int && message is int) bindings['$chat:$message'] = path;
      }
    }
    bindings[audio.key] = path;
    store['files'] = paths;
    store['publishedFiles'] = published;
    store['bindings'] = bindings;
    await _save();
  }

  Future<void> _removePrivateCopy(String sourcePath) async {
    // Never use a substring test or delete a path supplied by MediaStore. Resolve
    // symlinks and require the source to be inside this installation's TDLib files.
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return;
      final root = await (await _dir()).resolveSymbolicLinks();
      final resolved = await source.resolveSymbolicLinks();
      final prefix =
          '$root${Platform.pathSeparator}files${Platform.pathSeparator}';
      if (resolved.startsWith(prefix)) await source.delete();
    } on FileSystemException {
      /* The persisted TDLib cleanup is retried later. */
    }
  }

  @override
  Future<Map<String, dynamic>> loadPreferences() async =>
      Map<String, dynamic>.from((await _store())['preferences'] as Map? ?? {});
  @override
  Future<void> savePreferences(Map<String, dynamic> value) async {
    (await _store())['preferences'] = value;
    await _save();
  }

  @override
  Future<List<TelegramAudio>> savedTransfers() async =>
      ((await _store())['transfers'] as List? ?? [])
          .map((e) => TelegramAudio.fromJson(e as Map<String, dynamic>))
          .toList();
  @override
  Future<void> saveTransfers(List<TelegramAudio> audio) async {
    (await _store())['transfers'] = audio.map((e) => e.toJson()).toList();
    await _save();
  }

  @override
  Future<bool> openMessage(TelegramAudio audio) =>
      _messageOpens[audio.key] ??= _openMessage(audio).whenComplete(() {
        _messageOpens.remove(audio.key);
      });

  Future<bool> _openMessage(TelegramAudio audio) async {
    var target = TelegramMessageLink.fromAudio(audio);
    // Private chats/basic groups have no shareable HTTPS message link. Their
    // app-only link also works without a live TDLib session.
    if (_transport != null && target?.appUri.host != 'openmessage') {
      final scope = 'message-link:${audio.key}';
      try {
        final response = await _td
            .read(scope, 'getMessageLink', {
              'chat_id': audio.chatId,
              'message_id': audio.messageId,
              'media_timestamp': 0,
              'for_album': false,
              'in_message_thread': false,
            })
            .timeout(const Duration(seconds: 3));
        target =
            TelegramMessageLink.fromHttps(response['link'] as String? ?? '') ??
            target;
      } catch (_) {
        // A missing/unavailable message link must not disable cached messages.
        _transport?.cancelReads(scope);
      }
    }
    if (target == null || _disposed) return false;
    try {
      return await _musicPublisher.openTelegramLink(
        target.appUri.toString(),
        fallbackLink: target.webUri?.toString(),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> coverPath(int fileId, {String localPath = ''}) async {
    final session = _sessionEpoch;
    final artworkEpoch = _artworkEpoch;
    if (_cacheClearing != null) return null;
    if (localPath.isNotEmpty && await File(localPath).exists()) {
      return localPath;
    }
    if (fileId <= 0) return null;
    final cached = (await _store())['cover:$fileId'] as String?;
    if (cached != null && await File(cached).exists()) return cached;
    if (_state != TelegramAuth.ready) return null;
    _coverRequests.add(fileId);
    late final Map<String, dynamic> file;
    try {
      file = await _td.read('covers', 'downloadFile', {
        'file_id': fileId,
        'priority': 1,
        'offset': 0,
        'limit': 0,
        'synchronous': true,
      });
    } finally {
      _coverRequests.remove(fileId);
    }
    final path = TelegramAudioMapper.completedPath(file);
    if (session != _sessionEpoch ||
        artworkEpoch != _artworkEpoch ||
        _disposed) {
      return null;
    }
    if (path.isEmpty) return null;
    final store = await _store();
    if (artworkEpoch != _artworkEpoch || _cacheClearing != null) return null;
    store['cover:$fileId'] = path;
    final keys = store.keys.where((key) => key.startsWith('cover:')).toList();
    for (final key in keys.take((keys.length - 512).clamp(0, keys.length))) {
      store.remove(key);
    }
    await _save();
    if (++_imageDownloads % 32 == 0) unawaited(_trimImageCache());
    return path;
  }

  Future<void> _trimImageCache() async {
    if (_transport == null || _disposed) return;
    try {
      await _td.call('optimizeStorage', {
        'size': 64 * 1024 * 1024,
        'ttl': 7 * 24 * 3600,
        'count': 512,
        'immunity_delay': 0,
        'file_types': [
          {'@type': 'fileTypeThumbnail'},
          {'@type': 'fileTypeProfilePhoto'},
        ],
        'chat_ids': [],
        'exclude_chat_ids': [],
        'return_deleted_file_statistics': false,
        'chat_limit': 0,
      });
    } catch (_) {
      /* Optional cache maintenance cannot block browsing. */
    }
  }

  @override
  Future<Map<String, String>> loadBindings() async =>
      TelegramCacheStore.paths((await _store())['bindings']);
  @override
  Future<void> bind(String key, String path) async {
    // Read/modify the shared snapshot without another await between them.
    final store = await _store();
    final bindings = TelegramCacheStore.paths(store['bindings']);
    bindings[key] = path;
    store['bindings'] = bindings;
    await _save();
  }

  @override
  Future<List<TelegramChat>> cachedChats() async =>
      ((await _store())['chats'] as List? ?? [])
          .map((e) => TelegramChat.fromJson(e as Map<String, dynamic>))
          .toList();
  @override
  Future<List<TelegramAudio>> cachedAudio(int chatId) async {
    final store = await _store();
    final paths = TelegramCacheStore.paths(store['files']);
    return (store['audio:$chatId'] as List? ?? []).map((e) {
      final audio = TelegramAudio.fromJson(e as Map<String, dynamic>);
      final path = paths['${audio.fileId}'];
      return path == null ? audio : audio.withLocalPath(path);
    }).toList();
  }

  @override
  Future<void> clearCache() =>
      _cacheClearing ??= _clearCache().whenComplete(() {
        _cacheClearing = null;
      });

  Future<void> _clearCache() async {
    ++_artworkEpoch;
    for (final scope in _browseVersions.keys.toList()) {
      _browseVersions[scope] = _browseVersions[scope]! + 1;
      _transport?.cancelReads(scope);
    }
    final covers = _coverRequests.toList();
    _transport?.cancelReads('covers');
    final store = await _store();
    final imagePaths = <String>{
      for (final entry in store.entries)
        if (entry.key.startsWith('cover:') && entry.value is String)
          entry.value as String,
      for (final chat in await cachedChats()) chat.photoPath,
      for (final entry in store.entries)
        if (entry.key.startsWith('audio:') && entry.value is List)
          for (final value in entry.value as List)
            TelegramAudio.fromJson(value as Map<String, dynamic>).coverPath,
    }..remove('');
    final audioPaths = <String>{
      for (final key in ['files', 'publishedFiles', 'bindings'])
        ...(store[key] as Map? ?? {}).values.whereType<String>(),
      for (final value in (store['temporaryAudio'] as Map? ?? {}).values)
        if (value is Map && value['localPath'] is String)
          value['localPath'] as String,
      for (final entry in store.entries)
        if (entry.key.startsWith('audio:') && entry.value is List)
          for (final value in entry.value as List)
            TelegramAudio.fromJson(value as Map<String, dynamic>).localPath,
    };
    // Covers evicted from the small JSON index may still exist in TDLib's
    // storage. Defer their native purge until the next connection if offline.
    store['imagePurgePending'] = true;
    await _save();
    if (_transport != null) {
      for (final id in covers) {
        await _td.call('cancelDownloadFile', {
          'file_id': id,
          'only_if_pending': false,
        });
      }
      await _purgeImageStorage();
      store.remove('imagePurgePending');
    }
    // Also works before connecting: only indexed images inside our own TDLib
    // directory may be deleted, never MediaStore paths or public music.
    for (final path in imagePaths) {
      if (audioPaths.contains(path) || _isInUse(path)) continue;
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final root = await (await _dir()).resolveSymbolicLinks();
        final resolved = await file.resolveSymbolicLinks();
        final prefix =
            '$root${Platform.pathSeparator}files${Platform.pathSeparator}';
        if (resolved.startsWith(prefix)) await file.delete();
      } on FileSystemException {
        throw const TelegramException(TelegramFailure.storage);
      }
    }
    store.removeWhere(
      (key, _) =>
          key == 'chats' ||
          key.startsWith('audio:') ||
          key.startsWith('cover:'),
    );
    _loadedChatIds.clear();
    _chatLimit = 50;
    await _save();
  }

  // Restrict TDLib cleanup to images; audio and paused downloads are untouched.
  Future<void> _purgeImageStorage() => _td
      .call('optimizeStorage', {
        'size': 0,
        'ttl': 0,
        'count': 0,
        'immunity_delay': 0,
        'file_types': [
          {'@type': 'fileTypeThumbnail'},
          {'@type': 'fileTypeProfilePhoto'},
        ],
        'chat_ids': [],
        'exclude_chat_ids': [],
        'return_deleted_file_statistics': false,
        'chat_limit': 0,
      })
      .then((_) {});

  @override
  Future<void> logout() async {
    _sessionEpoch++;
    await _td.call('logOut');
    await _secure.delete(key: 'telegram.session.active');
    await _cache.clear();
    _committedAudio.clear();
    await _subscription?.cancel();
    await _transport?.dispose();
    _transport = null;
    _emit(TelegramAuth.disconnected);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final completion in _completedFiles.values) {
      if (!completion.isCompleted) {
        completion.completeError(const TelegramTransferInterrupted());
      }
    }
    await _subscription?.cancel();
    await _transport?.dispose();
    await _cache.flush().catchError((Object _) {});
    await _auth.close();
    await _connection.close();
    await _files.close();
  }
}

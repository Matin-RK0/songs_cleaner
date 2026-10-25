import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'telegram_cache_store.dart';

import '../domain/telegram_models.dart';
import '../domain/telegram_repository.dart';
import 'tdlib_transport.dart';
import 'telegram_audio_mapper.dart';
import 'telegram_chat_mapper.dart';
import 'telegram_music_publisher.dart';
import '../domain/telegram_download.dart';

class TelegramRepositoryImpl implements TelegramRepository {
  TelegramRepositoryImpl({
    Directory? cacheDirectory,
    TelegramMusicPublisher? musicPublisher,
  }) : _directory = cacheDirectory,
       _musicPublisher = musicPublisher ?? TelegramMusicPublisher();

  final TelegramMusicPublisher _musicPublisher;
  final _downloads = <int, Future<String>>{};
  final _epochs = <int, int>{};
  final _progress = <int, void Function(TelegramTransferProgress)>{};
  final _completedFiles = <int, Completer<String>>{};
  final _savingAudio = <int>{};

  static const apiId = int.fromEnvironment('TELEGRAM_API_ID');
  static const apiHash = String.fromEnvironment('TELEGRAM_API_HASH');
  final _auth = StreamController<TelegramAuth>.broadcast();
  final _files = StreamController<TelegramLocalFile>.broadcast();
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'songs_cleaner_telegram'),
  );
  TdlibTransport? _transport;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  late final _cache = TelegramCacheStore(_dir);
  int _imageDownloads = 0;
  int _chatLimit = 50;
  bool _initializing = false;
  Future<void>? _readyPreparation;
  int _sessionEpoch = 0;
  bool _disposed = false;
  String? _key;
  Directory? _directory;
  TelegramAuth _state = TelegramAuth.disconnected;

  @override
  Stream<TelegramAuth> get authorization => _auth.stream;
  @override
  Stream<TelegramLocalFile> get fileUpdates => _files.stream;
  @override
  Future<bool> hasSession() async =>
      await _secure.read(key: 'telegram.session.active') == 'true';
  void _emit(TelegramAuth state) {
    _state = state;
    if (!_auth.isClosed) _auth.add(state);
  }

  Future<Directory> _dir() async => _directory ??= await Directory(
    '${(await getApplicationSupportDirectory()).path}/telegram',
  ).create(recursive: true);

  Future<Map<String, dynamic>> _store() => _cache.load();
  Future<void> _save() => _cache.save();

  @override
  Future<void> connect() async {
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
        _emit(_state);
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
      _key = await _secure.read(key: 'telegram.database.key');
      if (_key == null) {
        final random = Random.secure();
        _key = base64Encode(List.generate(32, (_) => random.nextInt(256)));
        await _secure.write(key: 'telegram.database.key', value: _key);
      }
      final transport = _transport = TdlibTransport();
      _subscription = transport.updates.listen((update) {
        if (update['@type'] == 'updateFile' && !_files.isClosed) {
          final file = update['file'] as Map<String, dynamic>;
          _acceptFile(file);
        }
        if (update['@type'] == 'updateAuthorizationState') {
          unawaited(
            _authorization(
              update['authorization_state'] as Map<String, dynamic>,
              dir,
            ).catchError((Object _) {
              _emit(TelegramAuth.disconnected);
            }),
          );
        }
      });
      await transport.start();
      final initial = await transport.call('getAuthorizationState');
      await _authorization(initial, dir);
    } catch (_) {
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
  }

  TdlibTransport get _td =>
      _transport ?? (throw const TelegramException(TelegramFailure.network));

  Future<void> _prepareReady() async {
    await _secure.write(key: 'telegram.session.active', value: 'true');
    await _pruneTemporary();
    unawaited(_trimImageCache());
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
  Future<List<TelegramChat>> chats({bool more = false}) async {
    if (more) {
      _chatLimit += 50;
    } else {
      _chatLimit = 50;
    }
    for (final list in ['chatListMain', 'chatListArchive']) {
      try {
        await _td.call('loadChats', {
          'chat_list': {'@type': list},
          'limit': _chatLimit,
        });
      } on TelegramException catch (e) {
        // TDLib uses 404 when the complete chat list has already been loaded.
        if (e.failure != TelegramFailure.generic) rethrow;
      }
    }
    final result = <TelegramChat>[];
    final seen = <int>{};
    for (final list in ['chatListMain', 'chatListArchive']) {
      final page = await _td.call('getChats', {
        'chat_list': {'@type': list},
        'limit': _chatLimit,
      });
      for (final id in page['chat_ids'] as List? ?? []) {
        if (!seen.add(id as int)) continue;
        final chat = await _td.call('getChat', {'chat_id': id});
        result.add(TelegramChatMapper.fromJson(chat));
      }
    }
    final store = await _store();
    store['chats'] = result.map((e) => e.toJson()).toList();
    await _save();
    return result;
  }

  @override
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0}) async {
    final response = await _td.call('searchChatMessages', {
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
    } catch (_) {
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
    final published = (store['publishedFiles'] as Map?)?['$fileId'] as String?;
    if (published != null && await File(published).exists()) return published;
    await _musicPublisher.ensureAccess();
    _checkEpoch(fileId, epoch);
    final cached = (store['files'] as Map?)?['$fileId'] as String?;
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
    await _td.call('deleteFile', {'file_id': id});
    final store = await _store();
    final staged = Map<String, dynamic>.from(
      store['temporaryAudio'] as Map? ?? {},
    )..remove('$id');
    store['temporaryAudio'] = staged;
    await _save();
  }

  Future<void> _pruneTemporary() async {
    final staged = Map<String, dynamic>.from(
      (await _store())['temporaryAudio'] as Map? ?? {},
    );
    for (final key in staged.keys) {
      final id = int.tryParse(key);
      if (id == null || _downloads.containsKey(id)) continue;
      try {
        await _discardTemporary(id);
      } catch (_) {
        /* Retry on next connection. */
      }
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
    if (await File(path).length() != await File(sourcePath).length()) {
      throw const TelegramException(TelegramFailure.storage);
    }
    final store = await _store();
    final paths = Map<String, String>.from(store['files'] as Map? ?? {});
    final published = Map<String, String>.from(
      store['publishedFiles'] as Map? ?? {},
    );
    paths['${audio.fileId}'] = path;
    published['${audio.fileId}'] = path;
    store['files'] = paths;
    store['publishedFiles'] = published;
    // Keep all cached messages for this file pointed at its permanent public copy.
    final bindings = Map<String, String>.from(store['bindings'] as Map? ?? {});
    for (final entry in store.entries) {
      if (!entry.key.startsWith('audio:') || entry.value is! List) continue;
      for (final value in entry.value as List) {
        final cachedAudio = TelegramAudio.fromJson(
          value as Map<String, dynamic>,
        );
        if (cachedAudio.fileId == audio.fileId) {
          bindings[cachedAudio.key] = path;
        }
      }
    }
    bindings[audio.key] = path;
    store['bindings'] = bindings;
    await _save();
    try {
      await _discardTemporary(audio.fileId);
    } catch (_) {
      /* Persisted cleanup record is retried on connection. */
    }
    await _removePrivateCopy(sourcePath);
    return path;
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
  Future<bool> openMessage(TelegramAudio audio) async {
    try {
      final response = await _td.call('getMessageLink', {
        'chat_id': audio.chatId,
        'message_id': audio.messageId,
        'media_timestamp': 0,
        'for_album': false,
        'in_message_thread': false,
      });
      return await _musicPublisher.openTelegramLink(response['link'] as String);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> coverPath(int fileId, {String localPath = ''}) async {
    final session = _sessionEpoch;
    if (localPath.isNotEmpty && await File(localPath).exists()) {
      return localPath;
    }
    if (fileId <= 0) return null;
    final cached = (await _store())['cover:$fileId'] as String?;
    if (cached != null && await File(cached).exists()) return cached;
    if (_state != TelegramAuth.ready) return null;
    final file = await _td.call('downloadFile', {
      'file_id': fileId,
      'priority': 1,
      'offset': 0,
      'limit': 0,
      'synchronous': true,
    });
    final path = TelegramAudioMapper.completedPath(file);
    if (session != _sessionEpoch || _disposed) return null;
    if (path.isEmpty) return null;
    final store = await _store();
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
      Map<String, String>.from((await _store())['bindings'] as Map? ?? {});
  @override
  Future<void> bind(String key, String path) async {
    // Read/modify the shared snapshot without another await between them.
    final store = await _store();
    final bindings = Map<String, String>.from(store['bindings'] as Map? ?? {});
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
    final paths = store['files'] as Map? ?? {};
    return (store['audio:$chatId'] as List? ?? []).map((e) {
      final audio = TelegramAudio.fromJson(e as Map<String, dynamic>);
      final path = paths['${audio.fileId}'] as String?;
      return path == null ? audio : audio.withLocalPath(path);
    }).toList();
  }

  @override
  Future<void> logout() async {
    _sessionEpoch++;
    await _td.call('logOut');
    await _secure.delete(key: 'telegram.session.active');
    await _cache.clear();
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
    await _files.close();
  }
}

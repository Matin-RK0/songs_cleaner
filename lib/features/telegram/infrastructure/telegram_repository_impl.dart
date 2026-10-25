import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/telegram_models.dart';
import '../domain/telegram_repository.dart';
import 'tdlib_transport.dart';

class TelegramRepositoryImpl implements TelegramRepository {
  static const apiId = int.fromEnvironment('TELEGRAM_API_ID');
  static const apiHash = String.fromEnvironment('TELEGRAM_API_HASH');
  final _auth = StreamController<TelegramAuth>.broadcast();
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'songs_cleaner_telegram'),
  );
  TdlibTransport? _transport;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Map<String, dynamic>? _cache;
  Future<void> _write = Future.value();
  int _chatLimit = 50;
  bool _initializing = false;
  bool _disposed = false;
  String? _key;
  Directory? _directory;
  TelegramAuth _state = TelegramAuth.disconnected;

  @override
  Stream<TelegramAuth> get authorization => _auth.stream;
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

  Future<Map<String, dynamic>> _store() async {
    if (_cache != null) return _cache!;
    final file = File('${(await _dir()).path}/library-v1.json');
    try {
      _cache = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _save() {
    final snapshot = jsonEncode(_cache);
    final next = _write.catchError((Object _) {}).then((_) async {
      final file = File('${(await _dir()).path}/library-v1.json');
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(snapshot, flush: true);
      await temp.rename(file.path);
    });
    _write = next;
    return next;
  }

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
      await _secure.write(key: 'telegram.session.active', value: 'true');
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
        result.add(
          TelegramChat(
            id: id,
            title: chat['title'] as String,
            kind: (chat['type'] as Map)['@type'] as String,
          ),
        );
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
      final message = value as Map<String, dynamic>;
      final content = message['content'] as Map<String, dynamic>;
      if (content['@type'] != 'messageAudio') continue;
      final audio = content['audio'] as Map<String, dynamic>;
      final file = audio['audio'] as Map<String, dynamic>;
      final local = file['local'] as Map<String, dynamic>;
      items.add(
        TelegramAudio(
          messageId: message['id'] as int,
          chatId: chatId,
          fileId: file['id'] as int,
          fileName: audio['file_name'] as String,
          size: file['size'] as int,
          title: audio['title'] as String,
          artist: audio['performer'] as String,
          duration: audio['duration'] as int,
          date: message['date'] as int,
          localPath: local['is_downloading_completed'] == true
              ? local['path'] as String
              : '',
        ),
      );
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
  Future<String> download(int fileId) async {
    // Request asynchronously, then query completion without blocking the UI.
    await _td.call('downloadFile', {
      'file_id': fileId,
      'priority': 16,
      'offset': 0,
      'limit': 0,
      'synchronous': false,
    });
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      final file = await _td.call('getFile', {'file_id': fileId});
      final local = file['local'] as Map<String, dynamic>;
      if (local['is_downloading_completed'] == true) {
        return local['path'] as String;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    await _td.call('cancelDownloadFile', {
      'file_id': fileId,
      'only_if_pending': false,
    });
    throw const TelegramException(TelegramFailure.network);
  }

  @override
  Future<Map<String, String>> loadBindings() async =>
      Map<String, String>.from((await _store())['bindings'] as Map? ?? {});
  @override
  Future<void> bind(String key, String path) async {
    final bindings = await loadBindings();
    bindings[key] = path;
    (await _store())['bindings'] = bindings;
    await _save();
  }

  @override
  Future<List<TelegramChat>> cachedChats() async =>
      ((await _store())['chats'] as List? ?? [])
          .map((e) => TelegramChat.fromJson(e as Map<String, dynamic>))
          .toList();
  @override
  Future<List<TelegramAudio>> cachedAudio(int chatId) async =>
      ((await _store())['audio:$chatId'] as List? ?? [])
          .map((e) => TelegramAudio.fromJson(e as Map<String, dynamic>))
          .toList();

  @override
  Future<void> logout() async {
    await _td.call('logOut');
    await _secure.delete(key: 'telegram.session.active');
    _cache = {};
    await _save();
    await _subscription?.cancel();
    await _transport?.dispose();
    _transport = null;
    _emit(TelegramAuth.disconnected);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _transport?.dispose();
    await _write.catchError((Object _) {});
    await _auth.close();
  }
}

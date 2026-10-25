import 'dart:async';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_repository.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_local_files.dart';

class FakeTelegramRepository implements TelegramRepository {
  final events = StreamController<TelegramAuth>.broadcast(sync: true);
  List<TelegramChat> savedChats = const [];
  List<TelegramAudio> savedAudio = const [];
  Map<String, String> bindings = {};
  TelegramAudioPage page = const TelegramAudioPage([], 0);
  TelegramFailure? failure;
  bool session = false;
  int connectCalls = 0;
  int audioCalls = 0;
  int downloadCalls = 0;
  int lastFromId = -1;
  String downloadedPath = '/app/song.mp3';
  Completer<void>? pendingDownload;
  @override
  Stream<TelegramAuth> get authorization => events.stream;
  @override
  Future<bool> hasSession() async => session;
  @override
  Future<void> connect() async {
    connectCalls++;
    events.add(TelegramAuth.phone);
  }

  @override
  Future<void> submitPhone(String phone) async => events.add(TelegramAuth.code);
  @override
  Future<void> submitCode(String code) async {
    if (failure != null) throw TelegramException(failure!);
    events.add(TelegramAuth.password);
  }

  @override
  Future<void> submitPassword(String password) async =>
      events.add(TelegramAuth.ready);
  @override
  Future<List<TelegramChat>> chats({bool more = false}) async => savedChats;
  @override
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0}) async {
    audioCalls++;
    lastFromId = fromId;
    if (failure != null) throw TelegramException(failure!);
    return page;
  }

  @override
  Future<String> download(int fileId) async {
    downloadCalls++;
    if (pendingDownload != null) await pendingDownload!.future;
    return downloadedPath;
  }

  @override
  Future<Map<String, String>> loadBindings() async => Map.of(bindings);
  @override
  Future<void> bind(String key, String path) async {
    bindings[key] = path;
  }

  @override
  Future<List<TelegramChat>> cachedChats() async => savedChats;
  @override
  Future<List<TelegramAudio>> cachedAudio(int chatId) async => savedAudio;
  @override
  Future<void> logout() async {
    bindings.clear();
    savedChats = [];
    savedAudio = [];
    events.add(TelegramAuth.disconnected);
  }

  @override
  Future<void> dispose() async => events.close();
}

class FakeTelegramLocalFiles extends TelegramLocalFiles {
  Set<String> existing = {};
  @override
  Future<Set<String>> existingPaths(Iterable<String> paths) async =>
      paths.where(existing.contains).toSet();
}

TelegramAudio testAudio({
  int messageId = 10,
  int chatId = 123,
  String localPath = '',
}) => TelegramAudio(
  messageId: messageId,
  chatId: chatId,
  fileId: messageId + 100,
  fileName: 'song.mp3',
  size: 1024,
  title: 'Song',
  artist: 'Artist',
  duration: 120,
  localPath: localPath,
);

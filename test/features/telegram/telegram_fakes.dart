import 'dart:async';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_repository.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_local_files.dart';

class FakeTelegramRepository implements TelegramRepository {
  Map<String, dynamic> preferences = {};
  List<TelegramAudio> transfers = [];
  final progressCallbacks = <int, void Function(TelegramTransferProgress)>{};
  final transferGates = <int, Completer<void>>{};
  Completer<void>? cancelGate;
  final _activeDownloads = <int>{};
  @override
  Future<bool> openMessage(TelegramAudio audio) async => false;
  @override
  Future<Map<String, dynamic>> loadPreferences() async => preferences;
  @override
  Future<void> savePreferences(Map<String, dynamic> value) async {
    preferences = value;
  }

  @override
  Future<List<TelegramAudio>> savedTransfers() async => transfers;
  @override
  Future<void> saveTransfers(List<TelegramAudio> value) async {
    transfers = value;
  }

  @override
  Future<void> cancelDownload(int fileId, {bool discard = false}) async {
    final gate = transferGates[fileId];
    if (gate != null &&
        !gate.isCompleted &&
        _activeDownloads.contains(fileId)) {
      gate.completeError(const TelegramTransferInterrupted());
    }
    if (pendingDownload != null &&
        !pendingDownload!.isCompleted &&
        _activeDownloads.contains(fileId)) {
      pendingDownload!.completeError(const TelegramTransferInterrupted());
    }
    if (cancelGate != null) await cancelGate!.future;
  }

  final events = StreamController<TelegramAuth>.broadcast(sync: true);
  final files = StreamController<TelegramLocalFile>.broadcast(sync: true);
  List<TelegramChat> savedChats = const [];
  List<TelegramAudio> savedAudio = const [];
  Map<String, String> bindings = {};
  TelegramAudioPage page = const TelegramAudioPage([], 0);
  TelegramFailure? failure;
  bool session = false;
  int connectCalls = 0;
  final submittedPhones = <String>[];
  Completer<void>? pendingPhone;
  int audioCalls = 0;
  int downloadCalls = 0;
  int lastFromId = -1;
  String downloadedPath = '/storage/emulated/0/Music/Telegram/song.mp3';
  Completer<void>? pendingDownload;
  @override
  Stream<TelegramAuth> get authorization => events.stream;
  @override
  Stream<TelegramLocalFile> get fileUpdates => files.stream;
  int coverCalls = 0;
  String? cover;
  Future<String?> Function(int)? loadCover;
  @override
  Future<String?> coverPath(int fileId, {String localPath = ''}) async {
    coverCalls++;
    if (loadCover != null) return loadCover!(fileId);
    return cover;
  }

  @override
  Future<bool> hasSession() async => session;
  @override
  Future<void> connect() async {
    connectCalls++;
    events.add(TelegramAuth.phone);
  }

  @override
  Future<void> submitPhone(String phone) async {
    submittedPhones.add(phone);
    await pendingPhone?.future;
    if (failure != null) throw TelegramException(failure!);
    events.add(TelegramAuth.code);
  }

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
  Future<String> download(
    TelegramAudio audio, {
    void Function(TelegramTransferProgress)? onProgress,
  }) async {
    downloadCalls++;
    _activeDownloads.add(audio.fileId);
    if (onProgress != null) progressCallbacks[audio.fileId] = onProgress;
    try {
      if (transferGates[audio.fileId] != null) {
        await transferGates[audio.fileId]!.future;
      } else if (pendingDownload != null) {
        await pendingDownload!.future;
      }
      if (failure != null) throw TelegramException(failure!);
      return downloadedPath;
    } finally {
      _activeDownloads.remove(audio.fileId);
    }
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
  Future<void> dispose() async {
    await events.close();
    await files.close();
  }
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
  String fileName = 'song.mp3',
  int size = 1024,
}) => TelegramAudio(
  messageId: messageId,
  chatId: chatId,
  fileId: messageId + 100,
  fileName: fileName,
  size: size,
  title: 'Song',
  artist: 'Artist',
  duration: 120,
  localPath: localPath,
);

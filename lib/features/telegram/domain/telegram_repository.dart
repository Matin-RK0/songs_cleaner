import 'telegram_models.dart';
import 'telegram_download.dart';

abstract class TelegramRepository {
  Stream<TelegramAuth> get authorization;
  Stream<TelegramLocalFile> get fileUpdates;
  Future<bool> hasSession();
  Future<void> connect();
  Future<void> submitPhone(String phone);
  Future<void> submitCode(String code);
  Future<void> submitPassword(String password);
  Future<List<TelegramChat>> chats({bool more = false});
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0});
  Future<String> download(
    TelegramAudio audio, {
    void Function(TelegramTransferProgress)? onProgress,
  });
  Future<void> cancelDownload(int fileId, {bool discard = false});
  Future<Map<String, dynamic>> loadPreferences();
  Future<void> savePreferences(Map<String, dynamic> value);
  Future<List<TelegramAudio>> savedTransfers();
  Future<void> saveTransfers(List<TelegramAudio> audio);
  Future<bool> openMessage(TelegramAudio audio);
  Future<String?> coverPath(int fileId, {String localPath = ''});
  Future<Map<String, String>> loadBindings();
  Future<void> bind(String key, String path);
  Future<List<TelegramChat>> cachedChats();
  Future<List<TelegramAudio>> cachedAudio(int chatId);
  Future<void> clearCache();
  Future<void> logout();
  Future<void> dispose();
}

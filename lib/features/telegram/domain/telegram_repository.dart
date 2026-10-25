import 'telegram_models.dart';

abstract class TelegramRepository {
  Stream<TelegramAuth> get authorization;
  Future<bool> hasSession();
  Future<void> connect();
  Future<void> submitPhone(String phone);
  Future<void> submitCode(String code);
  Future<void> submitPassword(String password);
  Future<List<TelegramChat>> chats({bool more = false});
  Future<TelegramAudioPage> audio(int chatId, {int fromId = 0});
  Future<String> download(int fileId);
  Future<Map<String, String>> loadBindings();
  Future<void> bind(String key, String path);
  Future<List<TelegramChat>> cachedChats();
  Future<List<TelegramAudio>> cachedAudio(int chatId);
  Future<void> logout();
  Future<void> dispose();
}

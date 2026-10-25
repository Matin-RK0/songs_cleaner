abstract final class TelegramConnectionPolicy {
  static const operationTimeout = Duration(seconds: 20);
  static const retryTimeout = Duration(seconds: 5);
  static const retryCooldown = Duration(seconds: 3);
}

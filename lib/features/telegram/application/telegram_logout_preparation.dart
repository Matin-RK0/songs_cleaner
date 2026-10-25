import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'telegram_download_controller.dart';
import 'telegram_preferences_controller.dart';
import 'telegram_controller.dart';
import 'telegram_artwork_provider.dart';

final telegramLogoutPreparationProvider = Provider<TelegramLogoutPreparation>(
  TelegramLogoutPreparation.new,
);

/// Coordinates consumers of authorization without making the authorization
/// provider depend directly on controllers that subscribe to it.
class TelegramLogoutPreparation {
  TelegramLogoutPreparation(this._ref);
  final Ref _ref;

  Future<void> prepare() async {
    final downloads = _ref.read(telegramDownloadsProvider.notifier);
    final preferences = _ref.read(telegramPreferencesProvider.notifier);
    await Future.wait([downloads.prepareLogout(), preferences.prepareLogout()]);
  }

  void unlock() {
    _ref.read(telegramDownloadsProvider.notifier).unlock();
    _ref.read(telegramPreferencesProvider.notifier).unlock();
  }

  void reset() {
    _ref.invalidate(telegramChatProvider);
    _ref.invalidate(telegramDownloadsProvider);
    _ref.invalidate(telegramPreferencesProvider);
    _ref.invalidate(telegramArtworkLoaderProvider);
  }
}

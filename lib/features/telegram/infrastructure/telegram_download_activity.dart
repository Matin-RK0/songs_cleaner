import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import 'telegram_music_publisher.dart';

class TelegramDownloadActivity {
  Future<void> update(int active, int queued, {String? languageCode}) async {
    final code =
        languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    final l10n = lookupAppLocalizations(Locale(code == 'fa' ? 'fa' : 'en'));
    try {
      await TelegramMusicPublisher.channel
          .invokeMethod<bool>('setDownloadActivity', {
            'active': active,
            'title': l10n.telegramDownloadNotification,
            'text': l10n.telegramDownloadSummary(active, queued, 0),
          });
    } on MissingPluginException {
      /* Android-only foreground activity. */
    } on PlatformException {
      /* An OS service restriction must not corrupt the download. */
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_repository.dart';

/// Selected app language. `null` means "follow the system locale"; the app
/// resolves it against `AppLocalizations.supportedLocales`.
final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

class AppLocaleController extends Notifier<Locale?> {
  static const String systemValue = 'system';

  @override
  Locale? build() {
    final stored = ref
        .watch(appSettingsRepositoryProvider)
        .loadLocale(systemValue);
    return stored == systemValue ? null : Locale(stored);
  }

  Future<void> setLocale(Locale? locale) async {
    if (state == locale) return;
    state = locale;
    await ref
        .read(appSettingsRepositoryProvider)
        .saveLocale(locale?.languageCode ?? systemValue);
  }
}

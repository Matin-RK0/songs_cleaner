import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class AppFontLicenses {
  static bool _registered = false;

  static void register() {
    if (_registered) return;
    _registered = true;
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString(
        'assets/fonts/roboto/OFL.txt',
      );
      yield LicenseEntryWithLineBreaks(const ['Roboto'], license);
    });
  }
}

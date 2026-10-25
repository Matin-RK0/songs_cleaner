import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class TelegramDiagnostics {
  static void report(String operation, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    developer.log(
      operation,
      name: 'songs_cleaner.telegram',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

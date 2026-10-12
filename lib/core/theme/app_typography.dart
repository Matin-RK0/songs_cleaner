import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// Single source of truth for the app font. Component-level styles
  /// (AppBar, TabBar, dialogs, buttons...) replace instead of merge, so every
  /// custom style must carry this explicitly. Colors are applied per theme in
  /// [AppTheme], never hardcoded here.
  static const String fontFamily = 'Vazirmatn';

  static const TextStyle songTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle songSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
  );
}

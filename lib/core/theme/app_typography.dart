import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  /// Single source of truth for the app font. Component-level styles
  /// (AppBar, TabBar, dialogs, buttons...) replace instead of merge, so every
  /// custom style must carry this explicitly.
  static const String fontFamily = 'Vazirmatn';

  static const TextStyle songTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textHigh,
  );

  static const TextStyle songSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );
}

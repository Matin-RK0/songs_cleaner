import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// Single source of truth for the app font. Component-level styles
  /// (AppBar, TabBar, dialogs, buttons...) replace instead of merge, so every
  /// custom style must carry this explicitly. Colors are applied per theme in
  /// [AppTheme], never hardcoded here.
  static const String fontFamily = 'Vazirmatn';

  /// Large screen heading (e.g. player/detail headers).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );

  /// AppBar title (theme-level).
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  /// Title of the now-playing header and queue sheet.
  static const TextStyle playerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  /// Artist line under the now-playing title.
  static const TextStyle playerArtist = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Title inside a bottom sheet or dialog.
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  /// Slightly smaller sheet heading (e.g. permission prompts).
  static const TextStyle sheetTitleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  /// Selected tab label (theme-level).
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Unselected tab label (theme-level).
  static const TextStyle tabLabelUnselected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  /// Section label inside a scrolling screen.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  /// Title of an empty/error state.
  static const TextStyle emptyStateTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Title of a compact card (grid tiles).
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  /// Primary line of a list/song row.
  static const TextStyle listTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle songTitle = listTitle;

  /// Emphasized list row / settings tile title.
  static const TextStyle emphasisTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Compact list row title (e.g. queue items).
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Uppercase-style settings section label.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  /// Title of a compact inline banner.
  static const TextStyle bannerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  /// Secondary line under a list/song row.
  static const TextStyle songSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
  );

  /// Short supporting/caption text.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Very small caption (banner/queue secondary text).
  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
  );

  /// Centered metadata line (e.g. "{count} songs · {duration}").
  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Multi-line body copy for empty states and messages.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Label of a filled/outlined action button.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  /// Multi-line body copy inside dialogs (theme-level).
  static const TextStyle dialogBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
}

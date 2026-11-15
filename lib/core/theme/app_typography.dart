import 'package:material_ui/material_ui.dart';

abstract final class AppTypography {
  static const nowPlayingTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );
  static const nowPlayingArtist = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Single source of truth for the app font. Component-level styles
  /// (AppBar, TabBar, dialogs, buttons...) replace instead of merge, so every
  /// custom style must carry this explicitly. Colors are applied per theme in
  /// [AppTheme], never hardcoded here.
  static const String fontFamily = 'Roboto';
  // Roboto does not contain Persian glyphs; keep explicit offline coverage.
  static const List<String> fontFamilyFallback = ['Vazirmatn'];

  static const nowPlayingTime = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large screen heading (e.g. player/detail headers).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );

  /// AppBar title (theme-level).
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  /// Title of the now-playing header and queue sheet.
  static const TextStyle playerTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  /// Artist line under the now-playing title.
  static const TextStyle playerArtist = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Title inside a bottom sheet or dialog.
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  /// Slightly smaller sheet heading (e.g. permission prompts).
  static const TextStyle sheetTitleSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  /// Selected tab label (theme-level).
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Unselected tab label (theme-level).
  static const TextStyle tabLabelUnselected = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  /// Section label inside a scrolling screen.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  /// Title of an empty/error state.
  static const TextStyle emptyStateTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// Title of a compact card (grid tiles).
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  /// Primary line of a list/song row.
  static const TextStyle listTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle songTitle = listTitle;

  /// Emphasized list row / settings tile title.
  static const TextStyle emphasisTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Compact list row title (e.g. queue items).
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Uppercase-style settings section label.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  /// Title of a compact inline banner.
  static const TextStyle bannerTitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  /// Secondary line under a list/song row.
  static const TextStyle songSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
  );

  /// Short supporting/caption text.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Very small caption (banner/queue secondary text).
  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
  );

  /// Centered metadata line (e.g. "{count} songs · {duration}").
  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Multi-line body copy for empty states and messages.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Label of a filled/outlined action button.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  /// Multi-line body copy inside dialogs (theme-level).
  static const TextStyle dialogBody = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
}

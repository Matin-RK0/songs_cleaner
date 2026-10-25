import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double iconHero = 64;
  static const double avatarSize = 48;
  static const double avatarLarge = 64;
  static const double trackRowHeight = 72;
  static const double trackArtwork = 56;
  static const double progressStroke = 2;
  static const double sheetHeightFactor = 0.85;
  static const double selectionMaxHeightFactor = 0.5;
  static const double selectionBottomPadding = 192;
  static const EdgeInsets hSmVXs = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );
  static const double contentMaxWidth = 560;

  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets hMdVSm = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md);
}

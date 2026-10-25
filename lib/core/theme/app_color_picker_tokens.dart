import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppColorPickerTokens {
  static const maxWidth = 560.0;
  static const fieldAspectRatio = 1.65;
  static const fieldMaxHeight = 240.0;
  static const indicatorSize = 24.0;
  static const indicatorBorder = 2.0;
  static const swatchSize = 48.0;
  static const previewHeight = 48.0;
  static const progressSize = 18.0;
  static const progressStroke = 2.0;
  static const actionMinHeight = 48.0;
  static const hueTrackHeight = 12.0;
  static const hueTrackInset = 24.0;
  static const white = Color(0xffffffff);
  static const black = Color(0xff000000);
  static const transparent = Color(0x00000000);
  static const darkNeutral = Color(0xff30343b);
  static const palette = [
    ...AppPrimaryPalette.colors,
    white,
    darkNeutral,
    black,
  ];
  static const rainbow = [
    Color(0xffff0000),
    Color(0xffffff00),
    Color(0xff00ff00),
    Color(0xff00ffff),
    Color(0xff0000ff),
    Color(0xffff00ff),
    Color(0xffff0000),
  ];
}

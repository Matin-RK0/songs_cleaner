import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Offset floatingActionEntryOffset = Offset(0, 0.18);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration ambientPrimary = Duration(seconds: 24);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
}

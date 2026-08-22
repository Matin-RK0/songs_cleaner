import 'package:flutter/material.dart';

abstract final class AppRadius {
  static final BorderRadius sm = BorderRadius.circular(8);
  static final BorderRadius md = BorderRadius.circular(12);
  static final BorderRadius lg = BorderRadius.circular(16);
  static final BorderRadius xl = BorderRadius.circular(24);
  static final BorderRadius pill = BorderRadius.circular(999);

  static const Radius radiusXlTopOnly = Radius.circular(24);
}

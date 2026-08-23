import 'package:flutter/material.dart';

abstract final class AppRadius {
  static final BorderRadius sm = BorderRadius.circular(6);
  static final BorderRadius md = BorderRadius.circular(10);
  static final BorderRadius lg = BorderRadius.circular(14);
  static final BorderRadius xl = BorderRadius.circular(20);
  static final BorderRadius pill = BorderRadius.circular(999);

  static const Radius radiusXlTopOnly = Radius.circular(20);
}

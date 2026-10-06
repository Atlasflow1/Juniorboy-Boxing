import 'package:flutter/material.dart';

/// Mode-independent colors used by brand assets and photographic overlays.
abstract final class AppColors {
  static const brandRed = Color(0xFFE50914);
  static const transparent = Colors.transparent;
  static const onAccent = Colors.white;
  static final heroScrimStart = Colors.black.withValues(alpha: 0.85);
  static final heroScrimEnd = Colors.black.withValues(alpha: 0);
}

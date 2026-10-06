import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentTint,
    required this.tabBar,
    required this.success,
    required this.warning,
  });
  final Color background,
      surface,
      elevated,
      separator,
      textPrimary,
      textSecondary,
      textTertiary,
      accent,
      accentTint,
      tabBar,
      success,
      warning;
  static const light = AppPalette(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    separator: Color(0xFFE5E5EA),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6E6E73),
    textTertiary: Color(0xFFAEAEB2),
    accent: Color(0xFFD70015),
    accentTint: Color(0xFFFFE5E7),
    tabBar: Color(0xFFF9F9F9),
    success: Color(0xFF248A3D),
    warning: Color(0xFFB25000),
  );
  static const dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    elevated: Color(0xFF2C2C2E),
    separator: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF636366),
    accent: Color(0xFFFF2D3A),
    accentTint: Color(0xFF3A1215),
    tabBar: Color(0xFF121212),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
  );
  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? separator,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentTint,
    Color? tabBar,
    Color? success,
    Color? warning,
  }) => AppPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    elevated: elevated ?? this.elevated,
    separator: separator ?? this.separator,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    accent: accent ?? this.accent,
    accentTint: accentTint ?? this.accentTint,
    tabBar: tabBar ?? this.tabBar,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      tabBar: Color.lerp(tabBar, other.tabBar, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

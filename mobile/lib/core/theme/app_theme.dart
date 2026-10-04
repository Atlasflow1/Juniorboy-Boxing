import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../resources/app_sizes.dart';
import '../resources/app_icons.dart';
import '../resources/app_colors.dart';
import '../widgets/app_icon.dart';
import 'app_palette.dart';

ThemeData? _lightTheme;
ThemeData? _darkTheme;
ThemeData get lightTheme =>
    _lightTheme ??= buildTheme(AppPalette.light, Brightness.light);
ThemeData get darkTheme =>
    _darkTheme ??= buildTheme(AppPalette.dark, Brightness.dark);

ThemeData buildTheme(AppPalette p, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final body = GoogleFonts.interTextTheme(
    base.textTheme,
  ).apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.radiusButton),
  );
  return base.copyWith(
    extensions: [p],
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: brightness,
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: p.accent,
      onSecondary: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.accent,
      onError: Colors.white,
      outline: p.separator,
    ),
    textTheme: body.copyWith(
      headlineMedium: GoogleFonts.oswald(
        fontSize: AppSizes.font32,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      titleLarge: GoogleFonts.oswald(
        fontSize: AppSizes.font22,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const AppIcon(AppIcons.chevronLeft),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
    ),
    dividerColor: p.separator,
    dividerTheme: DividerThemeData(color: p.separator, thickness: 0.5),
    listTileTheme: ListTileThemeData(
      iconColor: p.accent,
      textColor: p.textPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: p.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusInput),
        borderSide: BorderSide(color: p.accent),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: shape,
        textStyle: GoogleFonts.inter(
          fontSize: AppSizes.font16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: p.accentTint,
        foregroundColor: p.accent,
        side: BorderSide.none,
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accent),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.elevated,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : p.textPrimary,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: p.separator)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      modalBarrierColor: Colors.black54,
      dragHandleColor: p.separator,
      // Full-width sheets like iOS; the Material default caps the width.
      constraints: const BoxConstraints(minWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.elevated,
      contentTextStyle: body.bodyMedium?.copyWith(color: p.textPrimary),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:junior_boy_boxing/core/resources/app_icons.dart';
import 'package:junior_boy_boxing/core/theme/app_palette.dart';
import 'package:junior_boy_boxing/core/theme/app_theme.dart';
import 'package:junior_boy_boxing/core/theme/theme_provider.dart';
import 'package:junior_boy_boxing/core/widgets/settings_group.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  test(
    'theme mode values persist as stable names and old values use System',
    () {
      expect(parseThemeMode(null), ThemeMode.system);
      expect(parseThemeMode(true), ThemeMode.system);
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode(ThemeMode.dark.name), ThemeMode.dark);
      expect(parseThemeMode('unknown'), ThemeMode.system);
    },
  );

  for (final (name, theme, expected) in [
    ('light', lightTheme, AppPalette.light),
    ('dark', darkTheme, AppPalette.dark),
  ]) {
    testWidgets('theme tokens match the expected palette in $name mode', (
      tester,
    ) async {
      expect(theme.bottomSheetTheme.backgroundColor, expected.surface);
      expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
      expect(theme.colorScheme.onSurfaceVariant, expected.textSecondary);
      expect(theme.colorScheme.surfaceContainerHigh, expected.elevated);
      expect(theme.colorScheme.outlineVariant, expected.separator);
      expect(
        theme.inputDecorationTheme.hintStyle?.color,
        expected.textSecondary,
      );
      expect(theme.chipTheme.selectedColor, expected.accentTint);
      expect(theme.chipTheme.showCheckmark, false);
      expect(tester.takeException(), isNull);
    });
    testWidgets('grouped settings renders in $name mode', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SettingsGroup(
              children: [
                SettingsRow(
                  title: 'Membership',
                  icon: AppIcons.crown,
                  onTap: () {},
                ),
                SettingsRow(
                  title: 'Contact',
                  icon: AppIcons.phone,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Membership'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(
        tester.element(find.byType(SettingsGroup)).palette.accent,
        expected.accent,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';

const _useBlackBackgroundKey = 'useBlackBackground';

/// Whether the app is showing the plain black background instead of the
/// gray/teal brand background. Black is the app's primary theme, so it's
/// the default for anyone who hasn't chosen otherwise. Persisted locally
/// so it survives app restarts.
class BackgroundStyleNotifier extends Notifier<bool> {
  @override
  bool build() =>
      Hive.box('jbb_device').get(_useBlackBackgroundKey, defaultValue: true)
          as bool;

  Future<void> toggle(bool useBlack) async {
    state = useBlack;
    await Hive.box('jbb_device').put(_useBlackBackgroundKey, useBlack);
  }
}

final useBlackBackgroundProvider =
    NotifierProvider<BackgroundStyleNotifier, bool>(
      BackgroundStyleNotifier.new,
    );

final backgroundColorProvider = Provider<Color>((ref) {
  final useBlack = ref.watch(useBlackBackgroundProvider);
  return useBlack ? AppColors.blackBackground : AppColors.background;
});

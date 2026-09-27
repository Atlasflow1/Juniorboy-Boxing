import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A tap that fires twice before the first push has finished (a fast
/// double-tap on a card/banner, or a stray double pointer event) makes
/// go_router create two pages for the same location in the same frame.
/// Both pages end up wanting the same page/restoration key, which crashes
/// Navigator with `'!keyReservation.contains(key)': is not true`.
///
/// [safePush] ignores a repeat push to the same location that arrives
/// within [minGap] of the previous one, so a double-tap only navigates
/// once.
extension SafeNavigation on BuildContext {
  static DateTime? _lastPushAt;
  static String? _lastPushLocation;

  void safePush(
    String location, {
    Object? extra,
    Duration minGap = const Duration(milliseconds: 700),
  }) {
    final now = DateTime.now();
    if (_lastPushLocation == location &&
        _lastPushAt != null &&
        now.difference(_lastPushAt!) < minGap) {
      return;
    }
    _lastPushAt = now;
    _lastPushLocation = location;
    push(location, extra: extra);
  }
}

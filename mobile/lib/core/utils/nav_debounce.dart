import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../resources/app_durations.dart';
import '../router/app_routes.dart';

/// Switches to tab roots and pushes detail pages, ignoring rapid repeat taps.
extension SafeNavigation on BuildContext {
  static DateTime? _lastNavigationAt;
  static String? _lastNavigationLocation;

  static const _tabRoots = {
    AppRoutes.home,
    AppRoutes.bookings,
    AppRoutes.profile,
    AppRoutes.more,
    AppRoutes.admin,
  };

  void safeNavigate(
    String location, {
    Object? extra,
    Duration minGap = AppDurations.navigationDebounce,
  }) {
    final now = DateTime.now();
    if (_lastNavigationLocation == location &&
        _lastNavigationAt != null &&
        now.difference(_lastNavigationAt!) < minGap) {
      return;
    }
    _lastNavigationAt = now;
    _lastNavigationLocation = location;
    if (_tabRoots.contains(Uri.parse(location).path)) {
      go(location, extra: extra);
    } else {
      push(location, extra: extra);
    }
  }
}

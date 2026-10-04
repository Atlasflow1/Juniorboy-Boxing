import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/program_screen.dart';
import '../../features/profile/screens/waiver_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/booking/screens/book_class_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/membership/screens/membership_screen.dart';
import '../../features/store/screens/store_screen.dart';
import '../../features/profile/screens/more_screen.dart';
import '../../features/profile/screens/my_bookings_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/complete_profile_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/contact_screen.dart';
import '../../features/profile/screens/payments_screen.dart';
import '../../features/reviews/screens/reviews_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import '../../features/profile/screens/information_screen.dart';
import '../constants/app_strings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, next) => refresh.value++);
  ref.listen(profileProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final profile = ref.read(profileProvider);
      final isAuth = state.uri.path == AppRoutes.welcome;
      if (auth.isLoading) return null;
      final user = auth.value;
      if (user == null && !isAuth) return AppRoutes.welcome;
      final signedInWithGoogle =
          user != null &&
          !user.isAnonymous &&
          user.providerData.any((p) => p.providerId == 'google.com');
      if (signedInWithGoogle &&
          ![
            AppRoutes.completeProfile,
            AppRoutes.waiver,
            AppRoutes.privacy,
            AppRoutes.terms,
            AppRoutes.contact,
          ].contains(state.uri.path) &&
          (profile.value != null && !isProfileComplete(profile.value!))) {
        return AppRoutes.completeProfile;
      }
      if (user != null && isAuth) return AppRoutes.home;
      if (state.uri.path == AppRoutes.admin &&
          profile.value?['role'] != 'admin') {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (c, s) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (c, s) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedulePath,
                name: 'schedule',
                builder: (c, s) =>
                    ScheduleScreen(programId: s.uri.queryParameters['program']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.book,
                name: 'book',
                builder: (c, s) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.membership,
                name: 'membership',
                builder: (c, s) => const MembershipScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                name: 'more',
                builder: (c, s) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.store,
        name: 'store',
        builder: (c, s) => const StoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingPath,
        builder: (c, s) => BookClassScreen(scheduleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.bookingConfirmed,
        builder: (c, s) => const BookingConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        builder: (c, s) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (c, s) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (c, s) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (c, s) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (c, s) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviews,
        builder: (c, s) => const ReviewsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (c, s) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        builder: (c, s) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (c, s) => const InformationScreen(title: 'About Us'),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (c, s) => const InformationScreen(
          title: 'Privacy Policy',
          text: AppStrings.privacy,
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (c, s) => const InformationScreen(
          title: 'Terms of Service',
          text: AppStrings.terms,
        ),
      ),
      GoRoute(path: AppRoutes.waiver, builder: (c, s) => const WaiverScreen()),
      GoRoute(
        path: AppRoutes.programPath,
        builder: (c, s) => ProgramScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

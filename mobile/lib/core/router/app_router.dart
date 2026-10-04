import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../features/blog/screens/blog_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../widgets/jbb_bottom_nav.dart';
import '../constants/app_strings.dart';

final connectionProvider = StreamProvider(
  (ref) => Connectivity().onConnectivityChanged,
);
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, next) => refresh.value++);
  ref.listen(profileProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final profile = ref.read(profileProvider);
      final isAuth = state.uri.path == '/welcome';
      if (auth.isLoading) return null;
      final user = auth.value;
      if (user == null && !isAuth) return '/welcome';
      final signedInWithGoogle =
          user != null &&
          !user.isAnonymous &&
          user.providerData.any((p) => p.providerId == 'google.com');
      if (signedInWithGoogle &&
          ![
            '/complete-profile',
            '/waiver',
            '/privacy',
            '/terms',
            '/contact',
          ].contains(state.uri.path) &&
          (profile.value != null && !isProfileComplete(profile.value!))) {
        return '/complete-profile';
}
      if (user != null && isAuth) return '/home';
      if (state.uri.path == '/admin' && profile.value?['role'] != 'admin') {
        return '/home';
}
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      ShellRoute(
        builder: (c, s, child) => _Shell(location: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/schedule',
            builder: (c, s) =>
                ScheduleScreen(programId: s.uri.queryParameters['program']),
          ),
          GoRoute(
            path: '/membership',
            builder: (c, s) => const MembershipScreen(),
          ),
          GoRoute(path: '/more', builder: (c, s) => const MoreScreen()),
          GoRoute(path: '/store', builder: (c, s) => const StoreScreen()),
          GoRoute(path: '/bookings', builder: (c, s) => const MyBookingsScreen()),
        ],
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (c, s) => BookClassScreen(scheduleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-confirmed',
        builder: (c, s) => const BookingConfirmationScreen(),
      ),
      GoRoute(path: '/profile', builder: (c, s) => const EditProfileScreen()),
      GoRoute(
        path: '/complete-profile',
        builder: (c, s) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (c, s) => const NotificationsScreen(),
      ),
      GoRoute(path: '/payments', builder: (c, s) => const PaymentsScreen()),
      GoRoute(path: '/reviews', builder: (c, s) => const ReviewsScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(path: '/contact', builder: (c, s) => const ContactScreen()),
      GoRoute(
        path: '/about',
        builder: (c, s) => const _InformationScreen(title: 'About Us'),
      ),
      GoRoute(
        path: '/privacy',
        builder: (c, s) => const _LegalScreen(
          page: 'privacy',
          title: 'Privacy Policy',
          fallback: AppStrings.privacy,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (c, s) => const _LegalScreen(
          page: 'terms',
          title: 'Terms of Service',
          fallback: AppStrings.terms,
        ),
      ),
      GoRoute(path: '/waiver', builder: (c, s) => const WaiverScreen()),
      GoRoute(path: '/blog', builder: (c, s) => const BlogScreen()),
      GoRoute(
        path: '/programs/:id',
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

class _Shell extends ConsumerWidget {
  const _Shell({required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref
            .watch(connectionProvider)
            .value
            ?.contains(ConnectivityResult.none) ??
        false;
    final user = ref.watch(profileProvider).value;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Back from any other main tab goes to Home first, like Android's
        // usual bottom-nav pattern — only Home itself asks to exit.
        if (location != '/home') {
          context.go('/home');
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (confirmed == true) SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (offline)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade900,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Offline · Showing saved data',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (user?['isActive'] == false)
                const Expanded(
                  child: Center(
                    child: Text('Your account is inactive. Contact the gym.'),
                  ),
                )
              else
                Expanded(child: child),
            ],
          ),
        ),
        bottomNavigationBar: JbbBottomNav(location: location),
      ),
    );
  }
}

class _InformationScreen extends ConsumerWidget {
  const _InformationScreen({required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        ref.watch(settingsProvider).value?['aboutText'] ??
            'Discipline builds champions. Train, learn and grow at Junior Boy Boxing.',
        style: const TextStyle(height: 1.7),
      ),
    ),
  );
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({
    required this.page,
    required this.title,
    required this.fallback,
  });
  final String page;
  final String title;
  final String fallback;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.doc('legalDocuments/$page').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final text = (data != null && data['published'] == true) ? data['body'] as String : fallback;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(text, style: const TextStyle(height: 1.7)),
        );
      },
    ),
  );
}

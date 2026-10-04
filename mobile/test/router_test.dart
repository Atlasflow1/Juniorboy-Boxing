import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:junior_boy_boxing/core/router/app_router.dart';
import 'package:junior_boy_boxing/core/router/app_routes.dart';
import 'package:junior_boy_boxing/core/utils/nav_debounce.dart';
import 'package:junior_boy_boxing/features/auth/providers/auth_provider.dart';
import 'package:junior_boy_boxing/features/profile/providers/profile_provider.dart';

void main() {
  testWidgets('tab roots switch branches and detail pages still push', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(
            body: Column(
              children: [
                Text('branch:${shell.currentIndex}'),
                Expanded(child: shell),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => TextButton(
                    onPressed: () => context.safeNavigate(
                      AppRoutes.schedule(programId: 'boxing'),
                    ),
                    child: const Text('schedule'),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.schedulePath,
                  builder: (context, state) => TextButton(
                    onPressed: () => context.safeNavigate(AppRoutes.store),
                    child: Text(state.uri.queryParameters['program'] ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.store,
          builder: (context, state) => const Scaffold(body: Text('store')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('schedule'));
    await tester.pumpAndSettle();
    expect(find.text('branch:1'), findsOneWidget);
    expect(find.text('boxing'), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('boxing'));
    await tester.pumpAndSettle();
    expect(find.text('store'), findsOneWidget);
    expect(router.canPop(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });

  testWidgets(
    'profile updates preserve the existing router and navigation state',
    (tester) async {
      final profiles = StreamController<Map<String, dynamic>>.broadcast(
        sync: true,
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => Stream<User?>.value(null)),
          profileProvider.overrideWith((ref) => profiles.stream),
        ],
      );
      final router = container.read(routerProvider);
      profiles.add({'id': 'member', 'sessionsRemaining': 3});
      await tester.pump();
      expect(identical(container.read(routerProvider), router), isTrue);
      profiles.add({'id': 'member', 'sessionsRemaining': 4});
      await tester.pump();
      expect(identical(container.read(routerProvider), router), isTrue);
      // Dispose first: awaiting close() while Riverpod still listens never completes.
      container.dispose();
      await profiles.close();
    },
  );
}

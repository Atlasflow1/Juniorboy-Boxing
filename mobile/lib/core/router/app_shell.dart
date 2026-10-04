import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/providers/profile_provider.dart';
import '../widgets/jbb_bottom_nav.dart';

final connectionProvider = StreamProvider(
  (ref) => Connectivity().onConnectivityChanged,
);

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
                Expanded(child: navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: JbbBottomNav(navigationShell: navigationShell),
      ),
    );
  }
}

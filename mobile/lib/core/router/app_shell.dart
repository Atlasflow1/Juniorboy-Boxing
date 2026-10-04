import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../resources/app_colors.dart';
import '../resources/app_sizes.dart';
import '../resources/app_strings.dart';
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
            title: const Text(AppStrings.exitApp),
            content: const Text(AppStrings.areYouSureYouWantToExit),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.no),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.yes),
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
                  color: AppColors.offlineBanner,
                  padding: const EdgeInsets.all(AppSizes.s8),
                  child: const Text(
                    AppStrings.offlineSavedData,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (user?.isActive == false)
                const Expanded(
                  child: Center(child: Text(AppStrings.inactiveAccount)),
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

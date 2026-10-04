import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../providers/auth_provider.dart';

/// Entry screen: brand mark, a Google sign-in button, and a Skip button
/// (continue as guest).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeState();
}

class _WelcomeState extends ConsumerState<WelcomeScreen> {
  bool busy = false;
  bool googleBusy = false;

  Future<void> skip() async {
    setState(() => busy = true);
    try {
      await ref.read(authRepositoryProvider).continueAsGuest();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> signInGoogle() async {
    setState(() => googleBusy = true);
    try {
      await ref.read(authRepositoryProvider).googleSignIn();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s28),
        child: Column(
          children: [
            const Spacer(),
            Image.asset(
              AppAssets.welcome,
              width: AppSizes.welcomeLogoWidth,
              semanticLabel: AppStrings.gymName,
            ),
            const Spacer(),
            // Google sign-in button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: (busy || googleBusy) ? null : signInGoogle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                icon: googleBusy
                    ? const SizedBox(
                        width: AppSizes.s18,
                        height: AppSizes.s18,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.s2,
                        ),
                      )
                    : const AppIcon(AppIcons.logIn),
                label: const Text(
                  AppStrings.uiContinueWithGoogle,
                  style: TextStyle(
                    fontSize: AppSizes.font17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            // Skip button (guest)
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: (busy || googleBusy) ? null : skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: AppSizes.s18,
                        height: AppSizes.s18,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.s2,
                          color: AppColors.black,
                        ),
                      )
                    : const AppIcon(AppIcons.fastForward),
                label: const Text(
                  AppStrings.uiSkip,
                  style: TextStyle(
                    fontSize: AppSizes.font17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s24),
          ],
        ),
      ),
    ),
  );
}

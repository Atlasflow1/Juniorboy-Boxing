import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_icon.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(
              AppIcons.checkCircle,
              color: AppColors.materialGreen,
              size: AppSizes.confirmationIconSize,
            ),
            const SizedBox(height: AppSizes.s24),
            Text(
              "You’re booked in.",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSizes.s12),
            const Text(
              AppStrings.uiYourSessionCreditIsReservedSeeYouAt,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s32),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text(AppStrings.backToHome),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.bookings),
              child: const Text(AppStrings.viewMyBookings),
            ),
          ],
        ),
      ),
    ),
  );
}

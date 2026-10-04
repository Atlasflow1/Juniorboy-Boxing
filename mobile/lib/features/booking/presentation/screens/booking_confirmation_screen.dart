import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';

import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/widgets/app_icon.dart';

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
            AppIcon(
              AppIcons.checkCircle,
              color: context.palette.success,
              size: AppSizes.confirmationIconSize,
            ),
            SizedBox(height: AppSizes.s24),
            Text(
              "You’re booked in.",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppSizes.s12),
            Text(
              AppStrings.uiYourSessionCreditIsReservedSeeYouAt,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.s32),
            FilledButton(
              onPressed: () => context.safeNavigate(AppRoutes.home),
              child: Text(AppStrings.backToHome),
            ),
            TextButton(
              onPressed: () => context.safeNavigate(AppRoutes.bookings),
              child: Text(AppStrings.viewMyBookings),
            ),
          ],
        ),
      ),
    ),
  );
}

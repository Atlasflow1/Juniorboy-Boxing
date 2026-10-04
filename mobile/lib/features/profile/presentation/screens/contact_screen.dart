import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../providers/profile_provider.dart';
import '../../domain/gym_settings.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? GymSettings.empty;
    Future<void> open(Uri uri) async {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
            context.mounted) {
          showMessage(context, AppStrings.couldNotOpenThisLink);
        }
      } catch (e) {
        if (context.mounted) showMessage(context, friendlyError(e));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.contactUs)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s24),
        children: [
          Text(
            settings.coachName ?? AppStrings.uiCoachSharif,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSizes.s16),
          Text(settings.address ?? AppStrings.address),
          const SizedBox(height: AppSizes.s24),
          if ((settings.phone ?? '').isNotEmpty)
            ListTile(
              leading: const AppIcon(
                AppIcons.phone,
                color: AppColors.materialRed,
              ),
              title: Text(settings.phone!),
              onTap: () => open(Uri(scheme: 'tel', path: settings.phone!)),
            ),
          if ((settings.email ?? '').isNotEmpty)
            ListTile(
              leading: const AppIcon(
                AppIcons.mail,
                color: AppColors.materialRed,
              ),
              title: Text(settings.email!),
              onTap: () => open(Uri(scheme: 'mailto', path: settings.email!)),
            ),
          FilledButton(
            onPressed: () => open(
              Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': settings.address ?? AppStrings.address,
              }),
            ),
            child: const Text(AppStrings.getDirections),
          ),
          const SizedBox(height: AppSizes.s24),
          Text(
            AppStrings.uiOperatingHours,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final entry in settings.operatingHours.entries)
            ListTile(
              title: Text(entry.key.toString()),
              trailing: Text(entry.value.toString()),
            ),
          if (settings.operatingHours.isEmpty)
            const Text(AppStrings.contactTheGymToConfirmTrainingHours),
        ],
      ),
    );
  }
}

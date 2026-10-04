import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/settings_group.dart';
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
      appBar: AppBar(title: Text(AppStrings.contactUs)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s24),
        children: [
          Text(
            settings.coachName ?? AppStrings.uiCoachSharif,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: AppSizes.s16),
          Text(settings.address ?? AppStrings.address),
          SizedBox(height: AppSizes.s24),
          SettingsGroup(
            children: [
              if ((settings.phone ?? '').isNotEmpty)
                SettingsRow(
                  icon: AppIcons.phone,
                  title: settings.phone!,
                  onTap: () => open(Uri(scheme: 'tel', path: settings.phone!)),
                ),
              if ((settings.email ?? '').isNotEmpty)
                SettingsRow(
                  icon: AppIcons.mail,
                  title: settings.email!,
                  onTap: () =>
                      open(Uri(scheme: 'mailto', path: settings.email!)),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          FilledButton(
            onPressed: () => open(
              Uri.https('www.google.com', '/maps/search/', {
                'api': '1',
                'query': settings.address ?? AppStrings.address,
              }),
            ),
            child: Text(AppStrings.getDirections),
          ),
          SizedBox(height: AppSizes.s24),
          Text(
            AppStrings.uiOperatingHours,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (settings.operatingHours.isNotEmpty)
            SettingsGroup(
              children: [
                for (final entry in settings.operatingHours.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s14,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key.toString())),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (settings.operatingHours.isEmpty)
            Text(AppStrings.contactTheGymToConfirmTrainingHours),
        ],
      ),
    );
  }
}

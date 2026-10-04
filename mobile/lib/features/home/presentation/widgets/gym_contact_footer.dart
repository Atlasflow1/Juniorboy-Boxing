import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class GymContactFooter extends ConsumerWidget {
  const GymContactFooter({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(settingsProvider).value?.address ?? '';
    return Column(
      children: [
        if (address.isNotEmpty)
          InkWell(
            onTap: () async {
              try {
                await launchUrl(
                  Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': address,
                  }),
                  mode: LaunchMode.externalApplication,
                );
              } catch (error) {
                if (context.mounted) showMessage(context, friendlyError(error));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.s8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    AppIcons.location,
                    size: AppSizes.s16,
                    color: context.palette.accent,
                  ),
                  const SizedBox(width: AppSizes.s6),
                  Flexible(
                    child: Text(
                      address,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.palette.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => context.safeNavigate(AppRoutes.contact),
          icon: const AppIcon(AppIcons.mail, size: AppSizes.s18),
          label: const Text(AppStrings.contactUs),
        ),
      ],
    );
  }
}

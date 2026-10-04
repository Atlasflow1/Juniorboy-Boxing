import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../profile/providers/profile_provider.dart';

/// The gym's address (admin-editable in the Admin Dashboard's "Gym Info"
/// card) plus a way to reach Contact Us — shown at the very bottom of
/// Home so it's always admin-controlled, never hardcoded. Tapping the
/// address opens it directly in Google Maps.
class GymContactFooter extends ConsumerWidget {
  const GymContactFooter({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address =
        (ref.watch(settingsProvider).value?['address'] as String?)?.trim() ??
        '';
    Future<void> openMaps() async {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
            context.mounted) {
          showMessage(context, 'Could not open Google Maps.');
        }
      } catch (e) {
        if (context.mounted) showMessage(context, friendlyError(e));
      }
    }

    return Column(
      children: [
        if (address.isNotEmpty) ...[
          InkWell(
            onTap: openMaps,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () => context.safePush('/contact'),
          icon: const Icon(Icons.mail_outline, size: 18),
          label: const Text('Contact Us'),
        ),
      ],
    );
  }
}

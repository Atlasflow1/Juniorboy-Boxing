import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../resources/app_sizes.dart';
import '../resources/app_icons.dart';
import '../resources/app_strings.dart';
import '../theme/app_palette.dart';
import '../utils/snackbar_utils.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import 'app_icon.dart';

const _icons = <String, String>{
  'instagram': AppIcons.instagram,
  'facebook': AppIcons.facebook,
  'tiktok': AppIcons.tiktok,
  'youtube': AppIcons.youtube,
};

class SocialLinksRow extends ConsumerWidget {
  const SocialLinksRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links =
        ref.watch(settingsProvider).value?.socialLinks ??
        const <String, String>{};
    final active = _icons.entries
        .where(
          (entry) => Uri.tryParse(links[entry.key] ?? '')?.scheme == 'https',
        )
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSizes.s10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(AppStrings.followUs),
        for (final entry in active)
          Tooltip(
            message: entry.key,
            child: InkWell(
              onTap: () async {
                try {
                  await launchUrl(
                    Uri.parse(links[entry.key]!),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (error) {
                  if (context.mounted) {
                    showMessage(context, friendlyError(error));
                  }
                }
              },
              child: CircleAvatar(
                backgroundColor: context.palette.accentTint,
                child: AppIcon(
                  entry.value,
                  size: AppSizes.s18,
                  color: context.palette.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

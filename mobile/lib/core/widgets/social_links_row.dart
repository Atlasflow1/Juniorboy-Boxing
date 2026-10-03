import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/snackbar_utils.dart';
import '../../features/profile/providers/profile_provider.dart';

const _socialIcons = {
  'instagram': 'assets/icons/ic_instagram.svg',
  'facebook': 'assets/icons/ic_facebook.svg',
  'tiktok': 'assets/icons/ic_tiktok.svg',
  'youtube': 'assets/icons/ic_youtube.svg',
};

/// The gym's social links as a row of equally-sized red-on-black circular
/// icons. Shared between Home (below the hero image) and the More screen, so
/// both stay visually identical.
class SocialLinksRow extends ConsumerWidget {
  const SocialLinksRow({super.key, this.label = 'Follow Us  '});
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? {};
    final links = (settings['socialLinks'] as Map?) ?? {};
    final active = _socialIcons.entries
        .where((e) => (links[e.key] ?? '').toString().startsWith('https://'))
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ...active.map(
          (e) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: e.key,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  try {
                    await launchUrl(
                      Uri.parse(links[e.key].toString()),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (err) {
                    if (context.mounted) {
                      showMessage(context, friendlyError(err));
                    }
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    e.value,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Colors.red,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/programs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../profile/providers/profile_provider.dart';
import '../../store/screens/store_screen.dart';
import '../providers/admin_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'ad_editor_screen.dart';
import 'plan_editor_screen.dart';
import 'program_editor_screen.dart';
import 'template_editor_screen.dart';

const _weekdayNames = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(adminPlansProvider);
    final templates = ref.watch(adminTemplatesProvider);
    final programs = ref.watch(adminProgramsProvider);
    final ads = ref.watch(adminAdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StoreScreen()),
            ),
            child: const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: AppColors.red),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Manage Store Products',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: AppColors.red),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Store Orders',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminSubscriptionsScreen(),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: AppColors.red),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Membership Subscriptions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_available_outlined, color: AppColors.red),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Bookings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _GymInfoSection(),
          const SizedBox(height: 24),
          const _SocialLinksSection(),
          const SizedBox(height: 24),
          const _PromoVideoSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Programs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgramEditorScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          programs.when(
            data: (rows) => Column(
              children: [
                for (final p in rows)
                  JbbCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProgramEditorScreen(program: p),
                      ),
                    ),
                    child: Row(
                      children: [
                        if ((p['imageUrl'] ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: p['imageUrl'],
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['className'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                [p['ageGroup'], p['priceLabel'], p['isActive'] == true ? 'Active' : 'Hidden']
                                    .where((s) => (s ?? '').toString().isNotEmpty)
                                    .join(' · '),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                  ),
              ],
            ),
            error: (e, s) => Text('Could not load programs: $e'),
            loading: () => const JbbLoading(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Membership Prices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          plans.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort(
                  (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                    b['sortOrder'] as num? ?? 0,
                  ),
                );
              return Column(
                children: [
                  for (final plan in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlanEditorScreen(plan: plan),
                        ),
                      ),
                      child: Row(
                        children: [
                          if ((plan['imageUrl'] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: plan['imageUrl'],
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['discountActive'] == true && (plan['discountPercent'] ?? 0) > 0
                                      ? '${plan['name'] ?? ''}  ·  ${plan['discountPercent']}% OFF'
                                      : plan['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan['priceLabel'] ?? ''} · ${plan['isActive'] == true ? 'Active' : 'Hidden'} · ${Programs.categories[plan['category']] ?? 'General'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text('Could not load plans: $e'),
            loading: () => const JbbLoading(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Class Schedule Times',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TemplateEditorScreen(),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          templates.when(
            data: (rows) {
              final sorted = [...rows]..sort((a, b) {
                final dayCompare = (a['dayOfWeek'] as num).compareTo(
                  b['dayOfWeek'] as num,
                );
                return dayCompare != 0
                    ? dayCompare
                    : (a['startTime'] as String).compareTo(
                        b['startTime'] as String,
                      );
              });
              if (sorted.isEmpty) {
                return const Text(
                  'No class times set up yet.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                children: [
                  for (final t in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TemplateEditorScreen(template: t),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weekdayNames[t['dayOfWeek']] ?? ''} · ${t['startTime']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${programs.value?.cast<Map<String, dynamic>?>().firstWhere((p) => p?['id'] == t['classId'], orElse: () => null)?['className'] ?? t['classId']} · ${t['maxSpots']} spots · ${t['isActive'] == true ? 'Active' : 'Paused'}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text('Could not load schedule times: $e'),
            loading: () => const JbbLoading(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Home Ads',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdEditorScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ads.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort(
                  (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                    b['sortOrder'] as num? ?? 0,
                  ),
                );
              if (sorted.isEmpty) {
                return const Text(
                  'No ads yet. Create one to feature it on the home page.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                children: [
                  for (final a in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdEditorScreen(ad: a),
                        ),
                      ),
                      child: Row(
                        children: [
                          if ((a['imageUrl'] ?? '').isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: a['imageUrl'],
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  [
                                    a['priceLabel'],
                                    a['isActive'] == true ? 'Active' : 'Hidden',
                                  ].where((s) => (s ?? '').toString().isNotEmpty).join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text('Could not load ads: $e'),
            loading: () => const JbbLoading(),
          ),
        ],
      ),
    );
  }
}

/// Lets the admin edit the gym's public address and phone number, shown
/// on the Contact screen and the website.
class _GymInfoSection extends ConsumerStatefulWidget {
  const _GymInfoSection();
  @override
  ConsumerState<_GymInfoSection> createState() => _GymInfoSectionState();
}

class _GymInfoSectionState extends ConsumerState<_GymInfoSection> {
  final address = TextEditingController(), phone = TextEditingController();
  bool loaded = false, busy = false;

  @override
  void dispose() {
    address.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveGymInfo(address.text.trim(), phone.text.trim());
      if (mounted) showMessage(context, 'Gym info saved.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      address.text = settings['address'] ?? '';
      phone.text = settings['phone'] ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gym Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shown on the Contact screen and the website.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          JbbButton(label: 'Save Gym Info', busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

/// Lets the admin set the gym's Instagram, Facebook, TikTok and YouTube
/// links — shown as icons on the website footer and the app's More screen.
class _SocialLinksSection extends ConsumerStatefulWidget {
  const _SocialLinksSection();
  @override
  ConsumerState<_SocialLinksSection> createState() => _SocialLinksSectionState();
}

class _SocialLinksSectionState extends ConsumerState<_SocialLinksSection> {
  final instagram = TextEditingController(),
      facebook = TextEditingController(),
      tiktok = TextEditingController(),
      youtube = TextEditingController();
  bool loaded = false, busy = false;

  @override
  void dispose() {
    instagram.dispose();
    facebook.dispose();
    tiktok.dispose();
    youtube.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).saveSocialLinks({
        'instagram': instagram.text.trim(),
        'facebook': facebook.text.trim(),
        'tiktok': tiktok.text.trim(),
        'youtube': youtube.text.trim(),
      });
      if (mounted) showMessage(context, 'Social links saved.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      final links = (settings['socialLinks'] as Map?) ?? {};
      instagram.text = links['instagram'] ?? '';
      facebook.text = links['facebook'] ?? '';
      tiktok.text = links['tiktok'] ?? '';
      youtube.text = links['youtube'] ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Links',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shown as icons on the website and the app\'s More screen.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: instagram,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Instagram URL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: facebook,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Facebook URL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tiktok,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'TikTok URL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: youtube,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'YouTube URL'),
          ),
          const SizedBox(height: 12),
          JbbButton(label: 'Save Social Links', busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

/// Lets the admin set the video that plays silently and on loop near the
/// top of Home — either upload a file from the phone (goes to Storage,
/// so there's never an embedding restriction), or paste a YouTube / direct
/// video link. Some YouTube videos block embedding elsewhere entirely (a
/// Content ID claim on the audio is the usual cause) and that can't be
/// worked around client-side, so uploading is the reliable option.
class _PromoVideoSection extends ConsumerStatefulWidget {
  const _PromoVideoSection();
  @override
  ConsumerState<_PromoVideoSection> createState() => _PromoVideoSectionState();
}

class _PromoVideoSectionState extends ConsumerState<_PromoVideoSection> {
  final url = TextEditingController();
  bool loaded = false, busy = false;

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final trimmed = url.text.trim();
    if (trimmed.isNotEmpty && Uri.tryParse(trimmed)?.hasScheme != true) {
      showMessage(context, 'That doesn\'t look like a valid link.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).savePromoVideoUrl(trimmed);
      if (mounted) {
        showMessage(
          context,
          trimmed.isEmpty ? 'Video removed from Home.' : 'Video saved.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickAndUpload() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .uploadPromoVideo(File(video.path));
      if (mounted) {
        url.text = ref.read(settingsProvider).value?['promoVideoUrl'] ?? '';
        showMessage(context, 'Video uploaded.');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      url.text = settings['promoVideoUrl'] ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo Video',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Plays silently on loop at the top of Home. Upload a video from '
            'your phone (most reliable — no embedding restrictions), or '
            'paste a YouTube / direct video link instead. If a YouTube '
            'video shows "video unavailable" on Home, YouTube itself is '
            'blocking it from being embedded — upload the file instead.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          JbbButton(
            label: 'Upload Video from Phone',
            busy: busy,
            onPressed: pickAndUpload,
          ),
          const SizedBox(height: 16),
          const Text(
            'Or paste a link',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: url,
            decoration: const InputDecoration(
              labelText: 'Video link',
              hintText: 'https://www.youtube.com/watch?v=... or https://.../video.mp4',
            ),
          ),
          const SizedBox(height: 12),
          JbbButton(label: 'Save Link', busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

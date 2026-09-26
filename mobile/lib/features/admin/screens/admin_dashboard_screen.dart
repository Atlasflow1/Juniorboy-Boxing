import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../home/widgets/promo_video_player.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/admin_provider.dart';
import 'plan_editor_screen.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          JbbCard(
            onTap: () => context.push('/store'),
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
          const SizedBox(height: 24),
          const _PromoVideoSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Membership Prices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan['priceLabel'] ?? ''} · ${plan['isActive'] == true ? 'Active' : 'Hidden'}',
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
                                  '${t['classId']} · ${t['maxSpots']} spots · ${t['isActive'] == true ? 'Active' : 'Paused'}',
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
        ],
      ),
    );
  }
}

/// Lets the admin upload the gym's own promo video, which then plays
/// silently on loop near the top of Home. Being the gym's own file (not
/// a YouTube embed), there's no embedding restriction to run into.
class _PromoVideoSection extends ConsumerStatefulWidget {
  const _PromoVideoSection();
  @override
  ConsumerState<_PromoVideoSection> createState() => _PromoVideoSectionState();
}

class _PromoVideoSectionState extends ConsumerState<_PromoVideoSection> {
  bool busy = false;

  Future<void> pickAndUpload() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .uploadPromoVideo(File(video.path));
      if (mounted) showMessage(context, 'Video uploaded.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).removePromoVideo();
      if (mounted) showMessage(context, 'Video removed from Home.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = ref.watch(settingsProvider).value?['promoVideoUrl'] ?? '';
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
            'Plays silently on loop at the top of Home. Upload a video from your phone, or remove it to hide the section.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if ((videoUrl as String).isNotEmpty) ...[
            PromoVideoPlayer(url: videoUrl),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: JbbButton(
                  label: videoUrl.isEmpty ? 'Upload Video' : 'Replace Video',
                  busy: busy,
                  onPressed: pickAndUpload,
                ),
              ),
              if (videoUrl.isNotEmpty) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: busy ? null : remove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

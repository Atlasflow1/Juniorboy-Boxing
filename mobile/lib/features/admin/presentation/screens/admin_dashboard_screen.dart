import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/programs.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../store/presentation/screens/store_screen.dart';
import '../providers/admin_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_subscriptions_screen.dart';
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
      appBar: AppBar(title: const Text(AppStrings.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s20),
        children: [
          JbbCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
            child: const Row(
              children: [
                AppIcon(AppIcons.shoppingBag, color: AppColors.red),
                SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Text(
                    AppStrings.uiManageStoreProducts,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
            ),
            child: const Row(
              children: [
                AppIcon(AppIcons.truck, color: AppColors.red),
                SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Text(
                    AppStrings.storeOrders,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminSubscriptionsScreen(),
              ),
            ),
            child: const Row(
              children: [
                AppIcon(AppIcons.crown, color: AppColors.red),
                SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Text(
                    AppStrings.membershipSubscriptions,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
            ),
            child: const Row(
              children: [
                AppIcon(AppIcons.calendarCheck, color: AppColors.red),
                SizedBox(width: AppSizes.s14),
                Expanded(
                  child: Text(
                    AppStrings.bookings,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                AppIcon(AppIcons.chevronRight, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s24),
          const _GymInfoSection(),
          const SizedBox(height: AppSizes.s24),
          const _PromoVideoSection(),
          const SizedBox(height: AppSizes.s24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.uiMembershipPrices,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
                ),
                icon: const AppIcon(AppIcons.plus, size: AppSizes.s18),
                label: const Text(AppStrings.add),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          plans.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
                                  plan.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan.priceLabel} · ${plan.isActive == true ? AppStrings.uiActive : AppStrings.uiHidden2} · ${Programs.categories[plan.category] ?? AppStrings.uiGeneral}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: AppSizes.font12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppIcon(
                            AppIcons.chevronRight,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text(AppStrings.couldNotLoadPlans(e)),
            loading: () => const JbbLoading(),
          ),
          const SizedBox(height: AppSizes.s24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.uiClassScheduleTimes,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TemplateEditorScreen(),
                  ),
                ),
                icon: const AppIcon(AppIcons.plus, size: AppSizes.s18),
                label: const Text(AppStrings.add),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s8),
          templates.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort((a, b) {
                  final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
                  return dayCompare != 0
                      ? dayCompare
                      : (a.startTime ?? '').compareTo(b.startTime ?? '');
                });
              if (sorted.isEmpty) {
                return const Text(
                  AppStrings.uiNoClassTimesSetUpYet,
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                children: [
                  for (final t in sorted)
                    JbbCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TemplateEditorScreen(template: t),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weekdayNames[t.dayOfWeek] ?? ''} · ${t.startTime}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${t.classId} · ${t.maxSpots} spots · ${t.isActive == true ? AppStrings.uiActive : AppStrings.uiPaused}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: AppSizes.font12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppIcon(
                            AppIcons.chevronRight,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text(AppStrings.couldNotLoadScheduleTimes(e)),
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
      if (mounted) showMessage(context, AppStrings.gymInfoSaved);
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
      address.text = settings.address ?? '';
      phone.text = settings.phone ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.uiGymInfo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.font15,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          const Text(
            AppStrings.uiShownOnTheContactScreenAndTheWebsite,
            style: TextStyle(color: AppColors.muted, fontSize: AppSizes.font12),
          ),
          const SizedBox(height: AppSizes.s12),
          TextField(
            controller: address,
            decoration: const InputDecoration(labelText: AppStrings.address2),
          ),
          const SizedBox(height: AppSizes.s12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: AppStrings.phone),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbButton(label: AppStrings.saveGymInfo, busy: busy, onPressed: save),
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
      showMessage(context, AppStrings.thatDoesnTLookLikeAValid);
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).savePromoVideoUrl(trimmed);
      if (mounted) {
        showMessage(
          context,
          trimmed.isEmpty
              ? AppStrings.uiVideoRemovedFromHome
              : AppStrings.uiVideoSaved,
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
        url.text = ref.read(settingsProvider).value?.promoVideoUrl ?? '';
        showMessage(context, AppStrings.videoUploaded);
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
      url.text = settings.promoVideoUrl ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.uiPromoVideo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.font15,
            ),
          ),
          const SizedBox(height: AppSizes.s4),
          const Text(
            'Plays silently on loop at the top of Home. Upload a video from '
            'your phone (most reliable — no embedding restrictions), or '
            'paste a YouTube / direct video link instead. If a YouTube '
            'video shows "video unavailable" on Home, YouTube itself is '
            'blocking it from being embedded — upload the file instead.',
            style: TextStyle(color: AppColors.muted, fontSize: AppSizes.font12),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbButton(
            label: AppStrings.uploadVideoFromPhone,
            busy: busy,
            onPressed: pickAndUpload,
          ),
          const SizedBox(height: AppSizes.s16),
          const Text(
            AppStrings.uiOrPasteALink,
            style: TextStyle(color: AppColors.muted, fontSize: AppSizes.font12),
          ),
          const SizedBox(height: AppSizes.s8),
          TextField(
            controller: url,
            decoration: const InputDecoration(
              labelText: AppStrings.videoLink,
              hintText:
                  'https://www.youtube.com/watch?v=... or https://.../video.mp4',
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          JbbButton(label: AppStrings.saveLink, busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

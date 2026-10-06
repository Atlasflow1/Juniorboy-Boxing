import '../../../../core/theme/app_palette.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../home/domain/home_ad.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../../../core/widgets/jbb_card.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../sessions/models/session_model.dart';
import '../../../sessions/presentation/providers/session_provider.dart';
import '../../../store/presentation/screens/store_screen.dart';
import '../providers/admin_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_subscriptions_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s20),
        children: [
          SettingsGroup(
            children: [
              SettingsRow(
                icon: AppIcons.shoppingBag,
                title: AppStrings.uiManageStoreProducts,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
              ),
              SettingsRow(
                icon: AppIcons.truck,
                title: AppStrings.storeOrders,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                ),
              ),
              SettingsRow(
                icon: AppIcons.crown,
                title: AppStrings.membershipSubscriptions,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminSubscriptionsScreen(),
                  ),
                ),
              ),
              SettingsRow(
                icon: AppIcons.calendarCheck,
                title: AppStrings.bookings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminBookingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.s24),
          const _CatalogSection(),
          SizedBox(height: AppSizes.s24),
          const _GymInfoSection(),
          SizedBox(height: AppSizes.s24),
          const _SocialLinksSection(),
          SizedBox(height: AppSizes.s24),
          const _PromoVideoSection(),
          SizedBox(height: AppSizes.s24),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.uiSessions,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.font17,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.safeNavigate(AppRoutes.adminSessionEditor),
                icon: AppIcon(AppIcons.plus, size: AppSizes.s18),
                label: Text(AppStrings.add),
              ),
            ],
          ),
          SizedBox(height: AppSizes.s8),
          sessions.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort((a, b) => a.startDate.compareTo(b.startDate));
              if (sorted.isEmpty) {
                return Text(
                  AppStrings.uiNoSessionsYet,
                  style: TextStyle(color: context.palette.textSecondary),
                );
              }
              return Column(
                children: [
                  for (final SessionModel s in sorted)
                    JbbCard(
                      onTap: () => context.safeNavigate(
                        AppRoutes.adminSessionEditor,
                        extra: s,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${DateFormat('MMM d').format(s.startDate)}–${DateFormat('MMM d').format(s.endDate)} · ${s.startTime}-${s.endTime} · ${s.joinedUserIds.length}/${s.maxParticipants} joined',
                                  style: TextStyle(
                                    color: context.palette.textSecondary,
                                    fontSize: AppSizes.font12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIcon(
                            AppIcons.chevronRight,
                            color: context.palette.textSecondary,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (e, s) => Text(AppStrings.couldNotLoadSessions(e)),
            loading: () => JbbLoading(),
          ),
        ],
      ),
    );
  }
}

class _CatalogSection extends ConsumerWidget {
  const _CatalogSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adminAdsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CatalogHeading(
          title: AppStrings.homeAds,
          onAdd: () => context.safeNavigate(AppRoutes.adminAdEditor),
        ),
        ads.when(
          data: (rows) => Column(
            children: [
              for (final HomeAd ad in rows)
                JbbCard(
                  onTap: () =>
                      context.safeNavigate(AppRoutes.adminAdEditor, extra: ad),
                  child: Row(
                    children: [
                      Expanded(child: Text(ad.title)),
                      Text(
                        ad.isActive
                            ? AppStrings.uiActive
                            : AppStrings.uiHidden2,
                      ),
                      AppIcon(
                        AppIcons.chevronRight,
                        color: context.palette.textSecondary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          loading: () => const JbbLoading(),
          error: (e, _) => Text(friendlyError(e)),
        ),
      ],
    );
  }
}

class _CatalogHeading extends StatelessWidget {
  const _CatalogHeading({required this.title, required this.onAdd});
  final String title;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      TextButton.icon(
        onPressed: onAdd,
        icon: const AppIcon(AppIcons.plus),
        label: const Text(AppStrings.add),
      ),
    ],
  );
}

/// Lets the admin edit the gym's public address and phone number, shown
/// on the Contact screen and the website.
class _GymInfoSection extends ConsumerStatefulWidget {
  const _GymInfoSection();
  @override
  ConsumerState<_GymInfoSection> createState() => _GymInfoSectionState();
}

class _GymInfoSectionState extends ConsumerState<_GymInfoSection> {
  final houseNumber = TextEditingController(),
      streetName = TextEditingController(),
      city = TextEditingController(),
      country = TextEditingController(),
      zipCode = TextEditingController(),
      phone = TextEditingController();
  bool loaded = false, busy = false;
  @override
  void dispose() {
    for (final c in [houseNumber, streetName, city, country, zipCode, phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveGymInfo(
            houseNumber: houseNumber.text.trim(),
            streetName: streetName.text.trim(),
            city: city.text.trim(),
            country: country.text.trim(),
            zipCode: zipCode.text.trim(),
            phone: phone.text.trim(),
          );
      if (mounted) showMessage(context, AppStrings.gymInfoSaved);
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      final parsed = StructuredAddress.parse(settings.address);
      houseNumber.text = parsed.houseNumber;
      streetName.text = parsed.streetName;
      city.text = parsed.city;
      country.text = parsed.country;
      final parts = (settings.address ?? '').split(',').map((s) => s.trim()).toList();
      zipCode.text = settings.zipCode ?? (parts.length > 3 ? parts[2] : '');
      phone.text = settings.phone ?? '';
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.uiGymInfo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            AppStrings.gymAddressHelp,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          for (final field in [
            (houseNumber, AppStrings.houseNumber),
            (streetName, AppStrings.streetName),
            (city, AppStrings.city),
            (country, AppStrings.country),
            (zipCode, AppStrings.postalZipCode),
            (phone, AppStrings.phone),
          ]) ...[
            SizedBox(height: AppSizes.s12),
            TextField(
              controller: field.$1,
              decoration: InputDecoration(labelText: field.$2),
            ),
          ],
          SizedBox(height: AppSizes.s12),
          JbbButton(label: AppStrings.saveGymInfo, busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

class _SocialLinksSection extends ConsumerStatefulWidget {
  const _SocialLinksSection();
  @override
  ConsumerState<_SocialLinksSection> createState() =>
      _SocialLinksSectionState();
}

class _SocialLinksSectionState extends ConsumerState<_SocialLinksSection> {
  final fields = {
    for (final key in ['instagram', 'facebook', 'tiktok', 'youtube'])
      key: TextEditingController(),
  };
  bool loaded = false, busy = false;
  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveSocialLinks(
            fields.map((key, value) => MapEntry(key, value.text.trim())),
          );
      if (mounted) showMessage(context, AppStrings.socialLinksSaved);
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (!loaded && settings != null) {
      for (final entry in fields.entries) {
        entry.value.text = settings.socialLinks[entry.key] ?? '';
      }
      loaded = true;
    }
    return JbbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.socialLinks,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final entry in fields.entries) ...[
            SizedBox(height: AppSizes.s12),
            TextField(
              controller: entry.value,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: entry.key),
            ),
          ],
          SizedBox(height: AppSizes.s12),
          JbbButton(
            label: AppStrings.saveSocialLinks,
            busy: busy,
            onPressed: save,
          ),
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
    var trimmed = url.text.trim();
    // Pasting from some apps/browsers drops the scheme (e.g.
    // "youtube.com/watch?v=..." or "youtu.be/..."). Treat that as the
    // admin's intent rather than silently rejecting it.
    if (trimmed.isNotEmpty && !trimmed.contains('://')) {
      trimmed = 'https://$trimmed';
    }
    if (trimmed.isNotEmpty && Uri.tryParse(trimmed)?.hasScheme != true) {
      showMessage(context, AppStrings.thatDoesnTLookLikeAValid);
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).savePromoVideoUrl(trimmed);
      if (mounted) {
        url.text = trimmed;
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
          Text(
            AppStrings.uiPromoVideo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.font15,
            ),
          ),
          SizedBox(height: AppSizes.s4),
          Text(
            'Plays silently on loop at the top of Home. Upload a video from '
            'your phone (most reliable — no embedding restrictions), or '
            'paste a YouTube / direct video link instead. If a YouTube '
            'video shows "video unavailable" on Home, YouTube itself is '
            'blocking it from being embedded — upload the file instead.',
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: AppSizes.font12,
            ),
          ),
          SizedBox(height: AppSizes.s12),
          JbbButton(
            label: AppStrings.uploadVideoFromPhone,
            busy: busy,
            onPressed: pickAndUpload,
          ),
          SizedBox(height: AppSizes.s16),
          Text(
            AppStrings.uiOrPasteALink,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: AppSizes.font12,
            ),
          ),
          SizedBox(height: AppSizes.s8),
          TextField(
            controller: url,
            decoration: InputDecoration(
              labelText: AppStrings.videoLink,
              hintText:
                  'https://www.youtube.com/watch?v=... or https://.../video.mp4',
            ),
          ),
          SizedBox(height: AppSizes.s12),
          JbbButton(label: AppStrings.saveLink, busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

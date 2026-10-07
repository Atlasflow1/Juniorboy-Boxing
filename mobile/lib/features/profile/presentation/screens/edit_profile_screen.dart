import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(8, (_) => TextEditingController());
  bool loaded = false, busy = false, photoBusy = false;
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.save({
        'childName': fields[0].text.trim(),
        'childAge': int.tryParse(fields[1].text) ?? 0,
        'address': composeAddress(
          houseNumber: fields[2].text.trim(),
          streetName: fields[3].text.trim(),
          city: fields[4].text.trim(),
          country: fields[5].text.trim(),
        ),
        'zipCode': fields[6].text.trim(),
        'phone': fields[7].text.trim(),
      });
      if (mounted) showMessage(context, AppStrings.profileSaved);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: AppSizes.mediaMaxWidth,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => photoBusy = true);
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(File(image.path));
      if (mounted) showMessage(context, AppStrings.profilePhotoUpdated);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (!loaded && user != null) {
      final address = StructuredAddress.parse(user.address);
      final values = [
        user.childName,
        (user.childAge) > 0 ? '${user.childAge}' : '',
        address.houseNumber,
        address.streetName,
        address.city,
        address.country,
        user.zipCode,
        user.phone,
      ];
      for (var i = 0; i < fields.length; i++) {
        fields[i].text = values[i] ?? '';
      }
      loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s20),
        child: Form(
          key: form,
          child: Column(
            children: [
              GestureDetector(
                onTap: photoBusy ? null : pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: AppSizes.avatarRadiusProfile,
                      backgroundColor: context.palette.accentTint,
                      backgroundImage: (user?.avatarUrl ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(user!.avatarUrl!)
                          : null,
                      child: (user?.avatarUrl ?? '').isEmpty
                          ? AppIcon(
                              AppIcons.user,
                              size: AppSizes.s40,
                              color: context.palette.accent,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: AppSizes.avatarRadiusSmall + AppSizes.s2,
                      backgroundColor: context.palette.surface,
                      child: CircleAvatar(
                        radius: AppSizes.avatarRadiusSmall,
                        backgroundColor: context.palette.accent,
                        child: const AppIcon(
                          AppIcons.imagePlus,
                          size: AppSizes.s16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s14),
                  child: TextFormField(
                    controller: fields[i],
                    keyboardType: [
                      TextInputType.text,
                      TextInputType.number,
                      TextInputType.text,
                      TextInputType.text,
                      TextInputType.text,
                      TextInputType.text,
                      TextInputType.text,
                      TextInputType.phone,
                    ][i],
                    decoration: InputDecoration(
                      labelText: [
                        AppStrings.participantNameYourselfOrChildOptional,
                        AppStrings.participantAgeOptional,
                        AppStrings.houseNumber,
                        AppStrings.streetName,
                        AppStrings.city,
                        AppStrings.country,
                        AppStrings.postalZipCode,
                        AppStrings.phone,
                      ][i],
                    ),
                    validator: [
                      null,
                      (String? value) => (value ?? '').trim().isEmpty
                          ? null
                          : Validators.age(value),
                      Validators.required,
                      Validators.required,
                      Validators.required,
                      Validators.required,
                      Validators.zip,
                      Validators.phone,
                    ][i],
                  ),
                ),
              JbbButton(
                label: AppStrings.saveChanges,
                busy: busy,
                onPressed: loaded ? save : null,
              ),
              SwitchListTile(
                title: const Text(AppStrings.pushNotifications),
                value: user?.pushNotifications ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'push': v,
                        'email': user?.emailNotifications ?? true,
                      },
                    });
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
              ),
              SwitchListTile(
                title: const Text(AppStrings.emailNotifications),
                value: user?.emailNotifications ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'email': v,
                        'push': user?.pushNotifications ?? true,
                      },
                    });
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                initialValue: user?.email ?? '',
                enabled: false,
                decoration: const InputDecoration(labelText: AppStrings.uiEmail),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

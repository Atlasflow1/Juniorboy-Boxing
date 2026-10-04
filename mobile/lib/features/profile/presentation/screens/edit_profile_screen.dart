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
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(9, (_) => TextEditingController());
  bool loaded = false, busy = false;
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
        'fullName': fields[0].text.trim(),
        'lastName': fields[1].text.trim(),
        'age': int.parse(fields[3].text),
        'address': fields[4].text.trim(),
        'zipCode': fields[5].text.trim(),
        'phone': fields[6].text.trim(),
        'childName': fields[7].text.trim(),
        'childAge': int.tryParse(fields[8].text) ?? 0,
      });
      if (fields[2].text.trim() !=
          ref.read(authRepositoryProvider).currentUser?.email) {
        await repo.changeEmail(fields[2].text.trim());
        if (mounted) {
          showMessage(context, AppStrings.profileSavedVerifyTheNewEmailTo);
        }
      } else if (mounted) {
        showMessage(context, AppStrings.profileSaved);
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (!loaded && user != null) {
      final values = [
        user.fullName,
        user.lastName,
        user.email,
        (user.age) > 0 ? '${user.age}' : '',
        user.address,
        user.zipCode,
        user.phone,
        user.childName,
        (user.childAge) > 0 ? '${user.childAge}' : '',
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
                onTap: busy
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: AppSizes.mediaMaxWidth,
                          imageQuality: 85,
                        );
                        if (image == null) return;
                        try {
                          await ref
                              .read(userRepositoryProvider)
                              .uploadAvatar(File(image.path));
                          if (context.mounted) {
                            showMessage(
                              context,
                              AppStrings.profilePhotoUpdated,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showMessage(context, friendlyError(e));
                          }
                        }
                      },
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
                      TextInputType.text,
                      TextInputType.emailAddress,
                      TextInputType.number,
                      TextInputType.text,
                      TextInputType.text,
                      TextInputType.phone,
                      TextInputType.text,
                      TextInputType.number,
                    ][i],
                    decoration: InputDecoration(
                      labelText: [
                        AppStrings.uiFullName,
                        AppStrings.lastName,
                        AppStrings.uiEmail,
                        AppStrings.yourAge,
                        AppStrings.address2,
                        AppStrings.postalZipCode,
                        AppStrings.phone,
                        "Child’s Name (optional)",
                        "Child’s Age (optional)",
                      ][i],
                    ),
                    validator: [
                      Validators.required,
                      Validators.required,
                      Validators.email,
                      Validators.age,
                      Validators.required,
                      Validators.zip,
                      Validators.phone,
                      null,
                      (v) =>
                          (v ?? '').trim().isEmpty ? null : Validators.age(v),
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
            ],
          ),
        ),
      ),
    );
  }
}

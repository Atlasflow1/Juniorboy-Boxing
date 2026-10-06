import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/utils/address_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends ConsumerState<CompleteProfileScreen> {
  final form = GlobalKey<FormState>(),
      fullName = TextEditingController(),
      lastName = TextEditingController(),
      age = TextEditingController(),
      houseNumber = TextEditingController(),
      streetName = TextEditingController(),
      city = TextEditingController(),
      country = TextEditingController(),
      zipCode = TextEditingController(),
      phone = TextEditingController(),
      childName = TextEditingController(),
      childAge = TextEditingController();
  bool busy = false, loaded = false, photoBusy = false;
  DateTime? dateOfBirth;
  @override
  void dispose() {
    fullName.dispose();
    lastName.dispose();
    age.dispose();
    houseNumber.dispose();
    streetName.dispose();
    city.dispose();
    country.dispose();
    zipCode.dispose();
    phone.dispose();
    childName.dispose();
    childAge.dispose();
    super.dispose();
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

  Future<void> pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => dateOfBirth = picked);
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (dateOfBirth == null) {
      showMessage(context, AppStrings.uiPickDate);
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(userRepositoryProvider).save({
        'fullName': fullName.text.trim(),
        'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        'lastName': lastName.text.trim(),
        'age': int.parse(age.text),
        'address': composeAddress(
          houseNumber: houseNumber.text.trim(),
          streetName: streetName.text.trim(),
          city: city.text.trim(),
          country: country.text.trim(),
        ),
        'zipCode': zipCode.text.trim(),
        'phone': phone.text.trim(),
        'childName': childName.text.trim(),
        'childAge': int.tryParse(childAge.text) ?? 0,
      });
      if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.home);
        }
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
    if (user != null && !loaded) {
      loaded = true;
      if (fullName.text.isEmpty) fullName.text = user.fullName ?? '';
      dateOfBirth ??= user.dateOfBirth;
      if (lastName.text.isEmpty) lastName.text = user.lastName ?? '';
      if (age.text.isEmpty && (user.age) > 0) {
        age.text = '${user.age}';
      }
      final parsed = StructuredAddress.parse(user.address);
      houseNumber.text = parsed.houseNumber;
      streetName.text = parsed.streetName;
      city.text = parsed.city;
      country.text = parsed.country;
      if (zipCode.text.isEmpty) zipCode.text = user.zipCode ?? '';
      if (phone.text.isEmpty) phone.text = user.phone ?? '';
      if (childName.text.isEmpty) childName.text = user.childName;
      if (childAge.text.isEmpty && (user.childAge) > 0) {
        childAge.text = '${user.childAge}';
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.completeYourProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.uiJustAFewMoreDetails,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.s10),
              const Text(AppStrings.uiWeNeedAFewAccountDetailsPlusWho),
              const SizedBox(height: AppSizes.s24),
              Center(
                child: GestureDetector(
                  onTap: photoBusy ? null : pickPhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: AppSizes.avatarRadiusProfile,
                        backgroundColor: context.palette.accentTint,
                        backgroundImage: user?.avatarUrl != null
                            ? CachedNetworkImageProvider(user!.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null
                            ? AppIcon(
                                AppIcons.user,
                                size: AppSizes.s40,
                                color: context.palette.accent,
                              )
                            : null,
                      ),
                      CircleAvatar(
                        radius: AppSizes.avatarRadiusSmall,
                        backgroundColor: context.palette.accent,
                        child: photoBusy
                            ? const CircularProgressIndicator()
                            : const AppIcon(
                                AppIcons.imagePlus,
                                size: AppSizes.s16,
                                color: AppColors.onAccent,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s24),
              TextFormField(
                controller: fullName,
                decoration: const InputDecoration(
                  labelText: AppStrings.uiFullName,
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: AppSizes.s16),
              InkWell(
                onTap: pickDateOfBirth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.uiDateOfBirth,
                  ),
                  child: Text(
                    dateOfBirth == null
                        ? AppStrings.uiPickDate
                        : DateFormat.yMMMd().format(dateOfBirth!),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: lastName,
                decoration: const InputDecoration(
                  labelText: AppStrings.lastName,
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.yourAge,
                ),
                validator: Validators.age,
              ),
              const SizedBox(height: AppSizes.s16),
              for (final field in [
                (houseNumber, AppStrings.houseNumber),
                (streetName, AppStrings.streetName),
                (city, AppStrings.city),
                (country, AppStrings.country),
              ]) ...[
                TextFormField(
                  controller: field.$1,
                  decoration: InputDecoration(labelText: field.$2),
                  validator: Validators.required,
                ),
                const SizedBox(height: AppSizes.s16),
              ],
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: zipCode,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: AppStrings.postalZipCode,
                ),
                validator: Validators.zip,
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: AppStrings.phone),
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: childName,
                decoration: const InputDecoration(
                  labelText: AppStrings.participantNameYourselfOrChildOptional,
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: childAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.participantAgeOptional,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? null : Validators.age(v),
              ),
              const SizedBox(height: AppSizes.s28),
              JbbButton(
                label: AppStrings.continueButton,
                busy: busy,
                onPressed: save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      lastName = TextEditingController(),
      age = TextEditingController(),
      address = TextEditingController(),
      zipCode = TextEditingController(),
      phone = TextEditingController(),
      childName = TextEditingController(),
      childAge = TextEditingController();
  bool busy = false, loaded = false;
  @override
  void dispose() {
    lastName.dispose();
    age.dispose();
    address.dispose();
    zipCode.dispose();
    phone.dispose();
    childName.dispose();
    childAge.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(userRepositoryProvider).save({
        'lastName': lastName.text.trim(),
        'age': int.parse(age.text),
        'address': address.text.trim(),
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
      if (lastName.text.isEmpty) lastName.text = user.lastName ?? '';
      if (age.text.isEmpty && (user.age) > 0) {
        age.text = '${user.age}';
      }
      if (address.text.isEmpty) address.text = user.address ?? '';
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
              const SizedBox(height: AppSizes.s32),
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
              TextFormField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: AppStrings.address2,
                ),
                validator: Validators.required,
              ),
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

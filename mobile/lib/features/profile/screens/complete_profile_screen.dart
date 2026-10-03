import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/address_utils.dart';
import '../../../core/widgets/jbb_button.dart';
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
      houseNumber = TextEditingController(),
      streetName = TextEditingController(),
      city = TextEditingController(),
      country = TextEditingController(),
      zipCode = TextEditingController(),
      phone = TextEditingController(),
      childName = TextEditingController(),
      childAge = TextEditingController();
  bool busy = false, loaded = false, photoBusy = false;
  @override
  void dispose() {
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
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => photoBusy = true);
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(File(image.path));
      if (mounted) showMessage(context, 'Profile photo updated.');
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await ref.read(userRepositoryProvider).save({
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
          context.go('/home');
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
      if (lastName.text.isEmpty) lastName.text = user['lastName'] ?? '';
      if (age.text.isEmpty && (user['age'] ?? 0) > 0) {
        age.text = '${user['age']}';
}
      if (streetName.text.isEmpty) streetName.text = user['address'] ?? '';
      if (zipCode.text.isEmpty) zipCode.text = user['zipCode'] ?? '';
      if (phone.text.isEmpty) phone.text = user['phone'] ?? '';
      if (childName.text.isEmpty) childName.text = user['childName'] ?? '';
      if (childAge.text.isEmpty && (user['childAge'] ?? 0) > 0) {
        childAge.text = '${user['childAge']}';
}
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Just a few more details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'We need a few account details, plus who will attend training.',
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: photoBusy ? null : pickPhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: (user?['avatarUrl'] ?? '').isNotEmpty
                            ? CachedNetworkImageProvider(user!['avatarUrl'])
                            : null,
                        child: (user?['avatarUrl'] ?? '').isEmpty
                            ? const Icon(Icons.person_outline, size: 40)
                            : null,
                      ),
                      CircleAvatar(
                        radius: 15,
                        child: photoBusy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_a_photo_outlined, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Your Age'),
                validator: Validators.age,
              ),
              const SizedBox(height: 24),
              Text('Address', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: houseNumber,
                decoration: const InputDecoration(
                  labelText: 'House / Building Number',
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: streetName,
                decoration: const InputDecoration(labelText: 'Street Name'),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: country,
                decoration: const InputDecoration(labelText: 'Country'),
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: zipCode,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Postal / ZIP Code'),
                validator: Validators.zip,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: childName,
                decoration: const InputDecoration(
                  labelText: 'Participant Name (Yourself or Child, optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: childAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Participant Age (optional)',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? null : Validators.age(v),
              ),
              const SizedBox(height: 28),
              JbbButton(label: 'Continue', busy: busy, onPressed: save),
            ],
          ),
        ),
      ),
    );
  }
}

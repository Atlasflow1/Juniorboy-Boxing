import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/address_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(12, (_) => TextEditingController());
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
        'fullName': fields[0].text.trim(),
        'lastName': fields[1].text.trim(),
        'age': int.parse(fields[3].text),
        'address': composeAddress(
          houseNumber: fields[4].text.trim(),
          streetName: fields[5].text.trim(),
          city: fields[6].text.trim(),
          country: fields[7].text.trim(),
        ),
        'zipCode': fields[8].text.trim(),
        'phone': fields[9].text.trim(),
        'childName': fields[10].text.trim(),
        'childAge': int.tryParse(fields[11].text) ?? 0,
      });
      if (fields[2].text.trim() != FirebaseAuth.instance.currentUser?.email) {
        await repo.changeEmail(fields[2].text.trim());
        if (mounted) {
          showMessage(
            context,
            'Profile saved. Verify the new email to complete the email change.',
          );
}
      } else if (mounted) {
        showMessage(context, 'Profile saved.');
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (!loaded && user != null) {
      final values = [
        user['fullName'],
        user['lastName'],
        user['email'],
        (user['age'] ?? 0) > 0 ? '${user['age']}' : '',
        '',
        user['address'],
        '',
        '',
        user['zipCode'],
        user['phone'],
        user['childName'],
        (user['childAge'] ?? 0) > 0 ? '${user['childAge']}' : '',
      ];
      for (var i = 0; i < fields.length; i++) {
        fields[i].text = values[i] ?? '';
      }
      loaded = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: form,
          child: Column(
            children: [
              Text(
                'Profile photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GestureDetector(
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_a_photo_outlined, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Your name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final i in [0, 1])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: fields[i],
                    decoration: InputDecoration(
                      labelText: ['Full Name', 'Last Name'][i],
                    ),
                    validator: Validators.required,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              for (final i in [2, 3])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: fields[i],
                    keyboardType: i == 2
                        ? TextInputType.emailAddress
                        : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: ['Email', 'Your Age'][i - 2],
                    ),
                    validator: i == 2 ? Validators.email : Validators.age,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              for (final i in [4, 5, 6, 7])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: fields[i],
                    decoration: InputDecoration(
                      labelText: [
                        'House / Building Number',
                        'Street Name',
                        'City',
                        'Country',
                      ][i - 4],
                    ),
                    validator: Validators.required,
                  ),
                ),
              for (final i in [8, 9])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextFormField(
                    controller: fields[i],
                    keyboardType: i == 8
                        ? TextInputType.text
                        : TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: ['Postal / ZIP Code', 'Phone'][i - 8],
                    ),
                    validator: i == 8 ? Validators.zip : Validators.phone,
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Participant',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: fields[10],
                  decoration: const InputDecoration(
                    labelText: "Child’s Name (optional)",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: fields[11],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Child’s Age (optional)",
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? null : Validators.age(v),
                ),
              ),
              JbbButton(
                label: 'Save Changes',
                busy: busy,
                onPressed: loaded ? save : null,
              ),
              SwitchListTile(
                title: const Text('Push notifications'),
                value: user?['notificationPreferences']?['push'] ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'push': v,
                        'email':
                            user?['notificationPreferences']?['email'] ?? true,
                      },
                    });
                  } catch (e) {
                    if (context.mounted) showMessage(context, friendlyError(e));
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Email notifications'),
                value: user?['notificationPreferences']?['email'] ?? true,
                onChanged: (v) async {
                  try {
                    await ref.read(userRepositoryProvider).save({
                      'notificationPreferences': {
                        'email': v,
                        'push':
                            user?['notificationPreferences']?['push'] ?? true,
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

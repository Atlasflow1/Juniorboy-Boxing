import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    if (!loaded && user != null) {
      final values = [
        user['fullName'],
        user['lastName'],
        user['email'],
        (user['age'] ?? 0) > 0 ? '${user['age']}' : '',
        user['address'],
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
              GestureDetector(
                onTap: busy
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          imageQuality: 85,
                        );
                        if (image == null) return;
                        try {
                          await ref
                              .read(userRepositoryProvider)
                              .uploadAvatar(File(image.path));
                          if (context.mounted) {
                            showMessage(context, 'Profile photo updated.');
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
                      radius: 48,
                      backgroundImage: (user?['avatarUrl'] ?? '').isNotEmpty
                          ? CachedNetworkImageProvider(user!['avatarUrl'])
                          : null,
                      child: (user?['avatarUrl'] ?? '').isEmpty
                          ? const Icon(Icons.person_outline, size: 40)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 15,
                      child: Icon(Icons.add_a_photo_outlined, size: 16),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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
                        'Full Name',
                        'Last Name',
                        'Email',
                        'Your Age',
                        'Address',
                        'Postal / ZIP Code',
                        'Phone',
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

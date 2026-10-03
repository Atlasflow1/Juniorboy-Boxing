import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/admin_provider.dart';

class ProgramEditorScreen extends ConsumerStatefulWidget {
  const ProgramEditorScreen({super.key, this.program});
  final Map<String, dynamic>? program;
  @override
  ConsumerState<ProgramEditorScreen> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends ConsumerState<ProgramEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.program?['id'] as String? ??
      FirebaseFirestore.instance.collection('classes').doc().id;
  late final className = TextEditingController(
    text: widget.program?['className'],
  );
  late final description = TextEditingController(
    text: widget.program?['description'],
  );
  late final ageGroup = TextEditingController(
    text: widget.program?['ageGroup'],
  );
  late final coachName = TextEditingController(
    text: widget.program?['coachName'],
  );
  late final price = TextEditingController(
    text: widget.program?['price'] != null
        ? (widget.program!['price'] / 100).toString()
        : '',
  );
  late final discountPercent = TextEditingController(
    text: ((widget.program?['discountPercent'] as num?) ?? 0) > 0
        ? '${widget.program!['discountPercent']}'
        : '',
  );
  late final durationMinutes = TextEditingController(
    text: '${widget.program?['durationMinutes'] ?? 60}',
  );
  late String imageUrl = widget.program?['imageUrl'] ?? '';
  late bool isActive = widget.program?['isActive'] ?? true;
  late bool discountActive = widget.program?['discountActive'] ?? false;
  bool busy = false, photoBusy = false;

  @override
  void dispose() {
    className.dispose();
    description.dispose();
    ageGroup.dispose();
    coachName.dispose();
    price.dispose();
    discountPercent.dispose();
    durationMinutes.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => photoBusy = true);
    try {
      final url = await ref
          .read(adminRepositoryProvider)
          .uploadProgramImage(id, File(image.path));
      if (mounted) setState(() => imageUrl = url);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cents = price.text.trim().isEmpty
        ? null
        : (double.parse(price.text) * 100).round();
    try {
      await ref.read(adminRepositoryProvider).saveProgram(id, {
        'className': className.text.trim(),
        'description': description.text.trim(),
        'ageGroup': ageGroup.text.trim(),
        'coachName': coachName.text.trim(),
        'price': cents,
        'priceLabel': cents != null ? '\$${(cents / 100).toStringAsFixed(2)}' : '',
        'discountActive': discountActive,
        'discountPercent': double.tryParse(discountPercent.text) ?? 0,
        'durationMinutes': int.parse(durationMinutes.text),
        'imageUrl': imageUrl,
        'location': 'Junior Boy Boxing',
        'address': widget.program?['address'] ?? '',
        'maxSpots': widget.program?['maxSpots'] ?? 12,
        'isActive': isActive,
        'createdAt': widget.program?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.program == null ? 'Add Program' : 'Edit Program'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: photoBusy ? null : pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12,
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(
                              child: Icon(Icons.add_photo_alternate_outlined, size: 36),
                            )
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 15,
                        child: photoBusy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_a_photo_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: className,
              decoration: const InputDecoration(labelText: 'Program name'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: ageGroup,
              decoration: const InputDecoration(labelText: 'Age group'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: coachName,
              decoration: const InputDecoration(labelText: 'Coach'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: durationMinutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration in minutes'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n != null && n >= 15 && n <= 240
                    ? null
                    : 'Enter 15–240 minutes';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price in USD (optional)'),
              validator: (v) => (v ?? '').trim().isEmpty || double.tryParse(v!) != null
                  ? null
                  : 'Enter a valid price',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: discountPercent,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Discount % (optional)'),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show discount badge'),
              subtitle: Text(
                (double.tryParse(discountPercent.text) ?? 0) > 0 &&
                        (double.tryParse(price.text) ?? 0) > 0
                    ? 'Customers will see: \$${(double.parse(price.text) * (1 - (double.tryParse(discountPercent.text) ?? 0) / 100)).toStringAsFixed(2)} (was \$${double.parse(price.text).toStringAsFixed(2)})'
                    : 'Set a price and discount % to preview.',
              ),
              value: discountActive,
              onChanged: (v) => setState(() => discountActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible to members)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 16),
            JbbButton(label: 'Save Program', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

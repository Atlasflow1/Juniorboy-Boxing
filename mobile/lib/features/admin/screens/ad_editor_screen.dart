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

class AdEditorScreen extends ConsumerStatefulWidget {
  const AdEditorScreen({super.key, this.ad});
  final Map<String, dynamic>? ad;
  @override
  ConsumerState<AdEditorScreen> createState() => _AdEditorState();
}

class _AdEditorState extends ConsumerState<AdEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.ad?['id'] as String? ??
      FirebaseFirestore.instance.collection('homeAds').doc().id;
  late final title = TextEditingController(text: widget.ad?['title']);
  late final description = TextEditingController(
    text: widget.ad?['description'],
  );
  late final price = TextEditingController(
    text: widget.ad?['price'] != null
        ? (widget.ad!['price'] / 100).toString()
        : '',
  );
  late final timeLabel = TextEditingController(text: widget.ad?['timeLabel']);
  late final linkHref = TextEditingController(
    text: widget.ad?['linkHref'] ?? '/pricing',
  );
  late String imageUrl = widget.ad?['imageUrl'] ?? '';
  late bool isActive = widget.ad?['isActive'] ?? true;
  bool busy = false, photoBusy = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    timeLabel.dispose();
    linkHref.dispose();
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
          .uploadAdImage(id, File(image.path));
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
      await ref.read(adminRepositoryProvider).saveAd(id, {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'imageUrl': imageUrl,
        'price': cents,
        'priceLabel': cents != null ? '\$${(cents / 100).toStringAsFixed(2)}' : '',
        'timeLabel': timeLabel.text.trim(),
        'linkHref': linkHref.text.trim().isEmpty ? '/pricing' : linkHref.text.trim(),
        'isActive': isActive,
        'sortOrder': widget.ad?['sortOrder'] ?? 0,
        'createdAt': widget.ad?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ad?'),
        content: Text('Remove "${title.text}" from the home page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteAd(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.ad == null ? 'Create Ad' : 'Edit Ad'),
      actions: [
        if (widget.ad != null)
          IconButton(
            onPressed: busy ? null : delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
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
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price in USD (optional)'),
              validator: (v) => (v ?? '').trim().isEmpty || double.tryParse(v!) != null
                  ? null
                  : 'Enter a valid price',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: timeLabel,
              decoration: const InputDecoration(
                labelText: 'Time / schedule note (optional)',
                hintText: 'e.g. Tonight · 6:00 PM',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: linkHref,
              decoration: const InputDecoration(labelText: 'Links to'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible on the home page)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 16),
            JbbButton(label: 'Save Ad', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

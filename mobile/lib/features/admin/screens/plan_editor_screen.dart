import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/programs.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/admin_provider.dart';

class PlanEditorScreen extends ConsumerStatefulWidget {
  const PlanEditorScreen({super.key, this.plan});
  final Map<String, dynamic>? plan;
  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.plan?['id'] as String? ??
      FirebaseFirestore.instance.collection('membershipPlans').doc().id;
  late final name = TextEditingController(text: widget.plan?['name']);
  late final description = TextEditingController(
    text: widget.plan?['description'],
  );
  late final perSessionLabel = TextEditingController(
    text: widget.plan?['perSessionLabel'],
  );
  late final price = TextEditingController(
    text: widget.plan?['price'] != null
        ? (widget.plan!['price'] / 100).toString()
        : '',
  );
  late final sessionCount = TextEditingController(
    text: widget.plan?['sessionCount'] != null
        ? '${widget.plan!['sessionCount']}'
        : '',
  );
  late bool isActive = widget.plan?['isActive'] ?? true;
  late bool isRecommended = widget.plan?['isRecommended'] ?? false;
  late bool discountActive = widget.plan?['discountActive'] ?? false;
  late final discountPercent = TextEditingController(
    text: ((widget.plan?['discountPercent'] as num?) ?? 0) > 0
        ? '${widget.plan!['discountPercent']}'
        : '',
  );
  late String category = widget.plan?['category'] ?? 'general';
  late String trainingType = widget.plan?['trainingType'] ?? 'private';
  late String imageUrl = widget.plan?['imageUrl'] ?? '';
  bool busy = false, photoBusy = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    perSessionLabel.dispose();
    price.dispose();
    sessionCount.dispose();
    discountPercent.dispose();
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
          .uploadPlanImage(id, File(image.path));
      if (mounted) setState(() => imageUrl = url);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => photoBusy = false);
    }
  }

  void removePhoto() => setState(() => imageUrl = '');

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cents = (double.parse(price.text) * 100).round();
    try {
      await ref.read(adminRepositoryProvider).savePlan(id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'perSessionLabel': perSessionLabel.text.trim(),
        'price': cents,
        'imageUrl': imageUrl,
        'priceLabel': '\$${(cents / 100).toStringAsFixed(2)}',
        'sessionCount': int.parse(sessionCount.text),
        'category': category,
        'trainingType': trainingType,
        'isActive': isActive,
        'isRecommended': isRecommended,
        'discountActive': discountActive,
        'discountPercent': double.tryParse(discountPercent.text) ?? 0,
        'sortOrder': widget.plan?['sortOrder'] ?? 0,
        'planType': widget.plan?['planType'] ?? 'package',
        'createdAt': widget.plan?['createdAt'] ?? FieldValue.serverTimestamp(),
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
        title: const Text('Delete plan?'),
        content: Text('Remove "${name.text}" from membership plans.'),
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
      await ref.read(adminRepositoryProvider).deletePlan(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.plan == null ? 'Add Plan' : 'Edit ${widget.plan!['name'] ?? 'Plan'}'),
      actions: [
        if (widget.plan != null)
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
                      height: 140,
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
                    if (imageUrl.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: removePhoto,
                          child: const CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Plan name'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: perSessionLabel,
              decoration: const InputDecoration(
                labelText: 'Rate description (e.g. "\$70 / session")',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price in USD'),
              validator: (v) =>
                  double.tryParse(v ?? '') != null && double.parse(v!) > 0
                  ? null
                  : 'Enter a valid price',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: sessionCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Session credits included',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n != null && n > 0 ? null : 'Enter a whole number > 0';
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Program'),
              items: [
                const DropdownMenuItem(
                  value: 'general',
                  child: Text('General (all programs)'),
                ),
                for (final entry in Programs.categories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() => category = v ?? 'general'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: trainingType,
              decoration: const InputDecoration(labelText: 'Training Type'),
              items: const [
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'group', child: Text('Group')),
                DropdownMenuItem(value: 'duo', child: Text('Duo')),
              ],
              onChanged: (v) => setState(() => trainingType = v ?? trainingType),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible to members)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recommended'),
              value: isRecommended,
              onChanged: (v) => setState(() => isRecommended = v),
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
            const SizedBox(height: 16),
            JbbButton(label: 'Save Plan', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

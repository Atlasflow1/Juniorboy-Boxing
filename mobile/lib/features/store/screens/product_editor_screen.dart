import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../providers/store_provider.dart';

class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.product});
  final Map<String, dynamic>? product;
  @override
  ConsumerState<ProductEditorScreen> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.product?['id'] as String? ??
      FirebaseFirestore.instance.collection('products').doc().id;
  late final name = TextEditingController(text: widget.product?['name']);
  late final description = TextEditingController(
    text: widget.product?['description'],
  );
  late final price = TextEditingController(
    text: widget.product?['price'] != null
        ? (widget.product!['price'] / 100).toString()
        : '',
  );
  late List<String> imageUrls = List<String>.from(
    widget.product?['imageUrls'] ??
        ((widget.product?['imageUrl'] ?? '').isNotEmpty
            ? [widget.product!['imageUrl']]
            : []),
  );
  late bool isActive = widget.product?['isActive'] ?? true;
  late bool isFeatured = widget.product?['isFeatured'] ?? false;
  late bool discountActive = widget.product?['discountActive'] ?? false;
  late final discountPercent = TextEditingController(
    text: ((widget.product?['discountPercent'] as num?) ?? 0) > 0
        ? '${widget.product!['discountPercent']}'
        : '',
  );
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    discountPercent.dispose();
    super.dispose();
  }

  Future<void> pickImage(int index) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => busy = true);
    try {
      final url = await ref
          .read(productRepositoryProvider)
          .uploadImage(id, index, File(image.path));
      if (mounted) {
        setState(() {
          while (imageUrls.length <= index) {
            imageUrls.add('');
          }
          imageUrls[index] = url;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void removeImage(int index) {
    if (index < imageUrls.length) setState(() => imageUrls[index] = '');
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final cents = (double.parse(price.text) * 100).round();
    try {
      final cleanImages = imageUrls.where((u) => u.isNotEmpty).toList();
      await ref.read(productRepositoryProvider).save(id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'price': cents,
        'priceLabel': '\$${(cents / 100).toStringAsFixed(2)}',
        'imageUrl': cleanImages.isNotEmpty ? cleanImages.first : '',
        'imageUrls': cleanImages,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'discountActive': discountActive,
        'discountPercent': double.tryParse(discountPercent.text) ?? 0,
        'sortOrder': widget.product?['sortOrder'] ?? 0,
        'createdAt': widget.product?['createdAt'] ?? FieldValue.serverTimestamp(),
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
        title: const Text('Delete product?'),
        content: Text('Remove "${name.text}" from the store.'),
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
      await ref.read(productRepositoryProvider).delete(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      actions: [
        if (widget.product != null)
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
            const Text(
              'Photos (up to 3)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final url = index < imageUrls.length ? imageUrls[index] : '';
                return GestureDetector(
                  onTap: busy
                      ? null
                      : () => url.isNotEmpty
                            ? showModalBottomSheet(
                                context: context,
                                builder: (_) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.swap_horiz),
                                        title: const Text('Replace photo'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          pickImage(index);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete_outline),
                                        title: const Text('Remove photo'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          removeImage(index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : pickImage(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.white10,
                      child: url.isNotEmpty
                          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              size: 28,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price in USD'),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  double.tryParse(v ?? '') != null && double.parse(v!) > 0
                  ? null
                  : 'Enter a valid price',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active (visible in the store)'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Feature on Home (product ad)'),
              subtitle: const Text(
                'Shows this product as a banner near the top of Home.',
              ),
              value: isFeatured,
              onChanged: (v) => setState(() => isFeatured = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: discountPercent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Discount % (optional)',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return null;
                final n = double.tryParse(v!);
                return n != null && n > 0 && n <= 100
                    ? null
                    : 'Enter 1-100';
              },
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
            JbbButton(label: 'Save Product', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

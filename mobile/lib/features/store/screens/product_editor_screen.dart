import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/product_sizes.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_icon.dart';
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
  late String category = widget.product?['category'] ?? 'other';
  late Set<String> selectedSizes = Set<String>.from(
    widget.product?['sizes'] ?? const [],
  );
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
      maxWidth: AppSizes.mediaMaxWidth,
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
        'category': category,
        'sizes': category == 'other' ? [] : selectedSizes.toList(),
        'discountActive': discountActive,
        'discountPercent': double.tryParse(discountPercent.text) ?? 0,
        'sortOrder': widget.product?['sortOrder'] ?? 0,
        'createdAt':
            widget.product?['createdAt'] ?? FieldValue.serverTimestamp(),
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
        title: const Text(AppStrings.deleteProduct),
        content: Text(AppStrings.removeProduct(name.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.delete),
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
      title: Text(
        widget.product == null
            ? AppStrings.addProduct
            : AppStrings.uiEditProduct,
      ),
      actions: [
        if (widget.product != null)
          IconButton(
            onPressed: busy ? null : delete,
            icon: const AppIcon(AppIcons.trash),
          ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.uiPhotosUpTo3,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.s8),
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
                                        leading: const AppIcon(AppIcons.swap),
                                        title: const Text(
                                          AppStrings.replacePhoto,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          pickImage(index);
                                        },
                                      ),
                                      ListTile(
                                        leading: const AppIcon(AppIcons.trash),
                                        title: const Text(
                                          AppStrings.removePhoto,
                                        ),
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
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                    child: Container(
                      width: AppSizes.productEditorPreviewSize,
                      height: AppSizes.productEditorPreviewSize,
                      color: AppColors.white10,
                      child: url.isNotEmpty
                          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                          : const AppIcon(
                              AppIcons.imagePlus,
                              size: AppSizes.s28,
                              color: AppColors.grey,
                            ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSizes.s24),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: AppStrings.productName,
              ),
              validator: Validators.required,
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(
                labelText: AppStrings.descriptionOptional,
              ),
              maxLines: AppSizes.descriptionInputLines,
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: AppStrings.priceInUsd,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  double.tryParse(v ?? '') != null && double.parse(v!) > 0
                  ? null
                  : AppStrings.uiEnterAValidPrice,
            ),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: AppStrings.category),
              items: [
                const DropdownMenuItem(
                  value: 'other',
                  child: Text(AppStrings.otherNoSizes),
                ),
                for (final entry in ProductSizes.categories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() {
                category = v ?? 'other';
                selectedSizes = selectedSizes.intersection(
                  ProductSizes.forCategory(category).toSet(),
                );
              }),
            ),
            if (category != 'other') ...[
              const SizedBox(height: AppSizes.s12),
              Text(
                AppStrings.uiAvailableSizesUs,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSizes.s8),
              Wrap(
                spacing: AppSizes.s8,
                runSpacing: AppSizes.s8,
                children: [
                  for (final size in ProductSizes.forCategory(category))
                    FilterChip(
                      label: Text(size),
                      selected: selectedSizes.contains(size),
                      onSelected: (v) => setState(
                        () => v
                            ? selectedSizes.add(size)
                            : selectedSizes.remove(size),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.s16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.activeVisibleInTheStore),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.featureOnHomeProductAd),
              subtitle: const Text(
                AppStrings.uiShowsThisProductAsABannerNearThe,
              ),
              value: isFeatured,
              onChanged: (v) => setState(() => isFeatured = v),
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: discountPercent,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: AppStrings.discountOptional,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return null;
                final n = double.tryParse(v!);
                return n != null && n > 0 && n <= 100
                    ? null
                    : AppStrings.uiEnter1100;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.showDiscountBadge),
              subtitle: Text(
                (double.tryParse(discountPercent.text) ?? 0) > 0 &&
                        (double.tryParse(price.text) ?? 0) > 0
                    ? 'Customers will see: \$${(double.parse(price.text) * (1 - (double.tryParse(discountPercent.text) ?? 0) / 100)).toStringAsFixed(2)} (was \$${double.parse(price.text).toStringAsFixed(2)})'
                    : AppStrings.uiSetAPriceAndDiscountToPreview,
              ),
              value: discountActive,
              onChanged: (v) => setState(() => discountActive = v),
            ),
            const SizedBox(height: AppSizes.s16),
            JbbButton(
              label: AppStrings.saveProduct,
              busy: busy,
              onPressed: save,
            ),
          ],
        ),
      ),
    ),
  );
}

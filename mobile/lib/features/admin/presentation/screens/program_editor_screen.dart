import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../providers/admin_provider.dart';
import '../../../schedule/domain/program.dart';

class ProgramEditorScreen extends ConsumerStatefulWidget {
  const ProgramEditorScreen({super.key, this.program});
  final Program? program;
  @override
  ConsumerState<ProgramEditorScreen> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends ConsumerState<ProgramEditorScreen> {
  final form = GlobalKey<FormState>();
  late final id =
      widget.program?.id ?? ref.read(adminRepositoryProvider).newId();
  late final className = TextEditingController(text: widget.program?.className);
  late final description = TextEditingController(
    text: widget.program?.description,
  );
  late final ageGroup = TextEditingController(text: widget.program?.ageGroup);
  late final coachName = TextEditingController(text: widget.program?.coachName);
  late final price = TextEditingController(
    text: widget.program?.price != null
        ? (widget.program!.price! / 100).toString()
        : '',
  );
  late final discountPercent = TextEditingController(
    text: (widget.program?.discountPercent ?? 0) > 0
        ? '${widget.program!.discountPercent}'
        : '',
  );
  late final durationMinutes = TextEditingController(
    text: '${widget.program?.durationMinutes ?? 60}',
  );
  static const _categories = ['Team', 'Individual', 'Weight Loss'];
  static const _trainingTypes = ['private', 'group', 'duo'];
  late String category = _categories.contains(widget.program?.category)
      ? widget.program!.category!
      : 'Individual';
  late String trainingType =
      _trainingTypes.contains(widget.program?.trainingType)
      ? widget.program!.trainingType!
      : 'private';
  late String imageUrl = widget.program?.imageUrl ?? '';
  late List<String> adImages = List<String>.from(
    widget.program?.adImages ?? const [],
  );
  late bool isActive = widget.program?.isActive ?? true;
  late bool discountActive = widget.program?.discountActive ?? false;
  bool busy = false, photoBusy = false, adPhotoBusy = false;

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

  Future<void> pickAdPhoto(int index) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => adPhotoBusy = true);
    try {
      final url = await ref
          .read(adminRepositoryProvider)
          .uploadProgramAdImage(id, index, File(image.path));
      if (mounted) {
        setState(() {
          while (adImages.length <= index) {
            adImages.add('');
          }
          adImages[index] = url;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => adPhotoBusy = false);
    }
  }

  void removeAdPhoto(int index) {
    if (index < adImages.length) setState(() => adImages[index] = '');
  }

  void removePhoto() => setState(() => imageUrl = '');

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
        'category': category,
        'trainingType': trainingType,
        'price': cents,
        'priceLabel': cents != null
            ? '\$${(cents / 100).toStringAsFixed(2)}'
            : '',
        'discountActive': discountActive,
        'discountPercent': double.tryParse(discountPercent.text) ?? 0,
        'durationMinutes': int.parse(durationMinutes.text),
        'imageUrl': imageUrl,
        'adImages': adImages.where((u) => u.isNotEmpty).toList(),
        'location': 'Junior Boy Boxing',
        'address': widget.program?.address ?? '',
        'maxSpots': widget.program?.maxSpots ?? 12,
        'isActive': isActive,
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
      title: Text(widget.program == null ? AppStrings.addProgram : 'Edit Program'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
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
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                        color: context.palette.accentTint,
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(
                              child: AppIcon(AppIcons.imagePlus, size: 36),
                            )
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.s8),
                      child: CircleAvatar(
                        radius: 15,
                        child: photoBusy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const AppIcon(AppIcons.imagePlus, size: 16),
                      ),
                    ),
                    if (imageUrl.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: removePhoto,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: context.palette.accent,
                            child: AppIcon(
                              AppIcons.circleX,
                              size: 16,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s20),
            TextFormField(
              controller: className,
              decoration: const InputDecoration(labelText: AppStrings.programName),
              validator: Validators.required,
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: AppStrings.description),
              maxLines: 2,
              validator: Validators.required,
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: ageGroup,
              decoration: const InputDecoration(labelText: AppStrings.ageGroup),
              validator: Validators.required,
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: coachName,
              decoration: const InputDecoration(labelText: AppStrings.coach),
              validator: Validators.required,
            ),
            const SizedBox(height: AppSizes.s16),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: AppStrings.category),
              items: const [
                DropdownMenuItem(value: 'Team', child: Text('Team')),
                DropdownMenuItem(
                  value: 'Individual',
                  child: Text('Individual'),
                ),
                DropdownMenuItem(
                  value: 'Weight Loss',
                  child: Text('Weight Loss'),
                ),
              ],
              onChanged: (v) => setState(() => category = v ?? category),
            ),
            const SizedBox(height: AppSizes.s16),
            DropdownButtonFormField<String>(
              initialValue: trainingType,
              decoration: const InputDecoration(labelText: 'Training Type'),
              items: const [
                DropdownMenuItem(value: 'private', child: Text(AppStrings.privateTraining)),
                DropdownMenuItem(value: 'group', child: Text(AppStrings.groupTraining)),
                DropdownMenuItem(value: 'duo', child: Text(AppStrings.duoTraining)),
              ],
              onChanged: (v) =>
                  setState(() => trainingType = v ?? trainingType),
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: durationMinutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.durationMinutes,
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n != null && n >= 15 && n <= 240
                    ? null
                    : 'Enter 15–240 minutes';
              },
            ),
            const SizedBox(height: AppSizes.s20),
            const Text(AppStrings.adPhotos),
            const SizedBox(height: AppSizes.s8),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: adPhotoBusy ? null : () => pickAdPhoto(i),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSizes.radius8),
                              color: context.palette.accentTint,
                              image:
                                  i < adImages.length && adImages[i].isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        adImages[i],
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: i >= adImages.length || adImages[i].isEmpty
                                ? const Center(
                                    child: AppIcon(AppIcons.plus, size: 22),
                                  )
                                : null,
                          ),
                          if (i < adImages.length && adImages[i].isNotEmpty)
                            GestureDetector(
                              onTap: () => removeAdPhoto(i),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: context.palette.accent,
                                child: AppIcon(
                                  AppIcons.circleX,
                                  size: 13,
                                  color: AppColors.onAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.s16),
            TextFormField(
              controller: price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: AppStrings.priceOptional,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || double.tryParse(v!) != null
                  ? null
                  : 'Enter a valid price',
              onChanged: (_) => setState(() {}),
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
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.showDiscountBadge),
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
              title: const Text(AppStrings.activeVisibleToMembers),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: AppSizes.s16),
            JbbButton(label: AppStrings.saveProgram, busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

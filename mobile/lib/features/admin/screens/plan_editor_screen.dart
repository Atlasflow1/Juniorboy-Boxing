import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late String category = widget.plan?['category'] ?? 'general';
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    perSessionLabel.dispose();
    price.dispose();
    sessionCount.dispose();
    super.dispose();
  }

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
        'priceLabel': '\$${(cents / 100).toStringAsFixed(2)}',
        'sessionCount': int.parse(sessionCount.text),
        'category': category,
        'isActive': isActive,
        'isRecommended': isRecommended,
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
            JbbButton(label: 'Save Plan', busy: busy, onPressed: save),
          ],
        ),
      ),
    ),
  );
}

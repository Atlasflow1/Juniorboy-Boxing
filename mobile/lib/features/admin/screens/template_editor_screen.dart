import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../providers/admin_provider.dart';

const _weekdays = [
  (1, 'Monday'),
  (2, 'Tuesday'),
  (3, 'Wednesday'),
  (4, 'Thursday'),
  (5, 'Friday'),
  (6, 'Saturday'),
  (7, 'Sunday'),
];

class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, this.template});
  final Map<String, dynamic>? template;
  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditorScreen> {
  final form = GlobalKey<FormState>();
  late String? classId = widget.template?['classId'];
  late int dayOfWeek = widget.template?['dayOfWeek'] ?? 1;
  late final startTime = TextEditingController(
    text: widget.template?['startTime'] ?? '16:00',
  );
  late final maxSpots = TextEditingController(
    text: (widget.template?['maxSpots'] ?? 12).toString(),
  );
  late bool isActive = widget.template?['isActive'] ?? true;
  bool busy = false;

  @override
  void dispose() {
    startTime.dispose();
    maxSpots.dispose();
    super.dispose();
  }

  /// Private sessions must have exactly 1 spot, Duo exactly 2 — Group is
  /// the admin's own choice. Returns null for Group (no fixed capacity).
  int? requiredCapacity(List<Map<String, dynamic>> classes) {
    final program = classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => <String, dynamic>{},
    );
    return switch (program['trainingType']) {
      'private' => 1,
      'duo' => 2,
      _ => null,
    };
  }

  void pickClass(String? id, List<Map<String, dynamic>> classes) {
    setState(() => classId = id);
    final program = classes.firstWhere(
      (c) => c['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    final cap = switch (program['trainingType']) {
      'private' => 1,
      'duo' => 2,
      _ => null,
    };
    if (cap != null) maxSpots.text = '$cap';
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || classId == null) return;
    setState(() => busy = true);
    // A random id (not classId_dayOfWeek) so the admin can add more than one
    // session for the same program — or different programs/categories — on
    // the same day without one silently overwriting another.
    final id =
        widget.template?['id'] ??
        FirebaseFirestore.instance.collection('recurringTemplates').doc().id;
    try {
      await ref.read(adminRepositoryProvider).saveTemplate(id, {
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime.text.trim(),
        'maxSpots': int.parse(maxSpots.text),
        'isActive': isActive,
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
        title: const Text('Remove this class time?'),
        content: const Text(
          'Future sessions already generated for it stay bookable; new ones stop being created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteTemplate(widget.template!['id']);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).value ?? [];
    final cap = requiredCapacity(classes);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Add Class Time' : 'Edit Class Time'),
        actions: [
          if (widget.template != null)
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
              DropdownButtonFormField<String>(
                // A template can reference a program that was since deleted
                // (or never existed). Passing that stale id as initialValue
                // would crash the dropdown (no matching item) — fall back to
                // unselected and let the admin pick a real program instead.
                initialValue: classes.any((c) => c['id'] == classId)
                    ? classId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Program',
                  helperText:
                      classId != null && !classes.any((c) => c['id'] == classId)
                      ? 'The program this was set to no longer exists — choose one.'
                      : null,
                ),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['className'] ?? c['id']),
                    ),
                ],
                onChanged: (v) => pickClass(v, classes),
                validator: (v) => v == null ? 'Choose a program' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day of week'),
                items: [
                  for (final d in _weekdays)
                    DropdownMenuItem(value: d.$1, child: Text(d.$2)),
                ],
                onChanged: (v) => setState(() => dayOfWeek = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: startTime,
                decoration: const InputDecoration(
                  labelText: 'Start time (24h, e.g. 16:00)',
                ),
                validator: (v) =>
                    RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                    ? null
                    : 'Use 24-hour HH:mm, e.g. 16:00',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: maxSpots,
                keyboardType: TextInputType.number,
                readOnly: cap != null,
                decoration: InputDecoration(
                  labelText: 'Max spots',
                  helperText: cap != null
                      ? 'Locked to $cap for this training type'
                      : null,
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') != null && int.parse(v!) > 0
                    ? null
                    : 'Enter a valid number',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active (generates weekly sessions)'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              const SizedBox(height: 16),
              JbbButton(
                label: widget.template == null ? 'Add Class Time' : 'Save Changes',
                busy: busy,
                onPressed: save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

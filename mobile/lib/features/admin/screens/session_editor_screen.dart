import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../providers/admin_provider.dart';

/// Creates or edits a one-off bookable session on a specific date — e.g.
/// "October 10, 10:00-11:00" — as opposed to a recurring weekly class time
/// (that's [TemplateEditorScreen]). Mirrors the web admin calendar's
/// "Add Session" form; editing an existing one-off session stays a web-only
/// capability (the web calendar already does this fully).
class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({super.key});
  @override
  ConsumerState<SessionEditorScreen> createState() => _SessionEditorState();
}

class _SessionEditorState extends ConsumerState<SessionEditorScreen> {
  final form = GlobalKey<FormState>();
  String? classId;
  DateTime? date;
  TimeOfDay? startTime, endTime;
  final maxSpots = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    maxSpots.dispose();
    super.dispose();
  }

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

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? startTime : endTime) ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null) {
      setState(() => isStart ? startTime = picked : endTime = picked);
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> save() async {
    if (!form.currentState!.validate() ||
        classId == null ||
        date == null ||
        startTime == null ||
        endTime == null) {
      showMessage(context, 'Fill in the program, date, start and end time.');
      return;
    }
    setState(() => busy = true);
    try {
      await ref.read(adminRepositoryProvider).saveSession(
        classId: classId!,
        date: DateFormat('yyyy-MM-dd').format(date!),
        startTime: _fmtTime(startTime!),
        endTime: _fmtTime(endTime!),
        maxSpots: int.parse(maxSpots.text),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).value ?? [];
    final cap = requiredCapacity(classes);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: classes.any((c) => c['id'] == classId)
                    ? classId
                    : null,
                decoration: const InputDecoration(labelText: 'Program'),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(
                        '${c['className'] ?? c['id']} (${switch (c['trainingType']) {
                          'group' => 'Group',
                          'duo' => 'Duo',
                          _ => 'Private',
                        }})',
                      ),
                    ),
                ],
                onChanged: (v) => pickClass(v, classes),
                validator: (v) => v == null ? 'Choose a program' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  date == null
                      ? 'Choose a date'
                      : DateFormat('EEEE, MMM d, yyyy').format(date!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: pickDate,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                subtitle: Text(
                  startTime == null ? 'Choose a start time' : _fmtTime(startTime!),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(true),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End time'),
                subtitle: Text(
                  endTime == null ? 'Choose an end time' : _fmtTime(endTime!),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => pickTime(false),
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
              const SizedBox(height: 16),
              JbbButton(label: 'Add Session', busy: busy, onPressed: save),
            ],
          ),
        ),
      ),
    );
  }
}

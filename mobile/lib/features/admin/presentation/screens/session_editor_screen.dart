import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../providers/admin_provider.dart';
import '../../../schedule/domain/program.dart';

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

  int? requiredCapacity(List<Program> classes) {
    final program = classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => Program.empty,
    );
    return switch (program.trainingType) {
      'private' => 1,
      'duo' => 2,
      _ => null,
    };
  }

  void pickClass(String? id, List<Program> classes) {
    setState(() => classId = id);
    final program = classes.firstWhere(
      (c) => c.id == id,
      orElse: () => Program.empty,
    );
    final cap = switch (program.trainingType) {
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
      initialTime:
          (isStart ? startTime : endTime) ??
          const TimeOfDay(hour: 16, minute: 0),
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
      await ref
          .read(adminRepositoryProvider)
          .saveSession(
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
      appBar: AppBar(title: const Text(AppStrings.addSession)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: classes.any((c) => c.id == classId)
                    ? classId
                    : null,
                decoration: const InputDecoration(labelText: AppStrings.program),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.className ?? c.id} (${switch (c.trainingType) {
                          'group' => AppStrings.groupTraining,
                          'duo' => AppStrings.duoTraining,
                          _ => AppStrings.privateTraining,
                        }})',
                      ),
                    ),
                ],
                onChanged: (v) => pickClass(v, classes),
                validator: (v) => v == null ? AppStrings.uiChooseAProgram : null,
              ),
              const SizedBox(height: AppSizes.s16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.uiDate),
                subtitle: Text(
                  date == null
                      ? 'Choose a date'
                      : DateFormat('EEEE, MMM d, yyyy').format(date!),
                ),
                trailing: const AppIcon(AppIcons.calendar),
                onTap: pickDate,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.startTime),
                subtitle: Text(
                  startTime == null
                      ? 'Choose a start time'
                      : _fmtTime(startTime!),
                ),
                trailing: const AppIcon(AppIcons.clock),
                onTap: () => pickTime(true),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.endTime),
                subtitle: Text(
                  endTime == null ? AppStrings.chooseEndTime : _fmtTime(endTime!),
                ),
                trailing: const AppIcon(AppIcons.clock),
                onTap: () => pickTime(false),
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: maxSpots,
                keyboardType: TextInputType.number,
                readOnly: cap != null,
                decoration: InputDecoration(
                  labelText: AppStrings.maxSpots,
                  helperText: cap != null
                      ? 'Locked to $cap for this training type'
                      : null,
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') != null && int.parse(v!) > 0
                    ? null
                    : 'Enter a valid number',
              ),
              const SizedBox(height: AppSizes.s16),
              JbbButton(label: AppStrings.addSession, busy: busy, onPressed: save),
            ],
          ),
        ),
      ),
    );
  }
}

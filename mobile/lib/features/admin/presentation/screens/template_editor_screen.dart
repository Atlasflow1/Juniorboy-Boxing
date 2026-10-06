import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../providers/admin_provider.dart';
import '../../domain/recurring_template.dart';
import '../../../schedule/domain/program.dart';

const _weekdays = [
  (1, AppStrings.uiMonday),
  (2, AppStrings.uiTuesday),
  (3, AppStrings.uiWednesday),
  (4, AppStrings.uiThursday),
  (5, AppStrings.uiFriday),
  (6, AppStrings.uiSaturday),
  (7, AppStrings.uiSunday),
];

class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, this.template});
  final RecurringTemplate? template;
  @override
  ConsumerState<TemplateEditorScreen> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditorScreen> {
  final form = GlobalKey<FormState>();
  late String? classId = widget.template?.classId;
  late int dayOfWeek = widget.template?.dayOfWeek ?? 1;
  late final startTime = TextEditingController(
    text: widget.template?.startTime ?? '16:00',
  );
  late final maxSpots = TextEditingController(
    text: (widget.template?.maxSpots ?? 12).toString(),
  );
  late bool isActive = widget.template?.isActive ?? true;
  bool busy = false;

  @override
  void dispose() {
    startTime.dispose();
    maxSpots.dispose();
    super.dispose();
  }

  int? requiredCapacity(List<Program> classes) {
    final program = classes.firstWhere(
      (p) => p.id == classId,
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
    final capacity = requiredCapacity(classes);
    if (capacity != null) maxSpots.text = '$capacity';
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || classId == null) return;
    setState(() => busy = true);
    final id = widget.template?.id ?? ref.read(adminRepositoryProvider).newId();
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
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeThisClassTime),
        content: const Text(
          AppStrings.uiFutureSessionsAlreadyGeneratedForItStayBookable,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteTemplate(widget.template!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider).value ?? [];
    final capacity = requiredCapacity(classes);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null
              ? AppStrings.uiAddClassTime
              : AppStrings.uiEditClassTime,
        ),
        actions: [
          if (widget.template != null)
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
              DropdownButtonFormField<String>(
                initialValue: classes.any((p) => p.id == classId)
                    ? classId
                    : null,
                decoration: InputDecoration(
                  labelText: AppStrings.program,
                  helperText:
                      classId != null && !classes.any((p) => p.id == classId)
                      ? AppStrings.programNoLongerExists
                      : null,
                ),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.className ?? c.id),
                    ),
                ],
                onChanged: (v) => pickClass(v, classes),
                validator: (v) =>
                    v == null ? AppStrings.uiChooseAProgram : null,
              ),
              const SizedBox(height: AppSizes.s16),
              DropdownButtonFormField<int>(
                initialValue: dayOfWeek,
                decoration: const InputDecoration(
                  labelText: AppStrings.dayOfWeek,
                ),
                items: [
                  for (final d in _weekdays)
                    DropdownMenuItem(value: d.$1, child: Text(d.$2)),
                ],
                onChanged: (v) => setState(() => dayOfWeek = v!),
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: startTime,
                decoration: const InputDecoration(
                  labelText: AppStrings.startTime24hEG1600,
                ),
                validator: (v) =>
                    RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                    ? null
                    : AppStrings.uiUse24HourHhMmEG16,
              ),
              const SizedBox(height: AppSizes.s16),
              TextFormField(
                controller: maxSpots,
                keyboardType: TextInputType.number,
                readOnly: capacity != null,
                decoration: InputDecoration(
                  labelText: AppStrings.maxSpots,
                  helperText: capacity == null
                      ? null
                      : AppStrings.capacityLocked(capacity),
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') != null && int.parse(v!) > 0
                    ? null
                    : AppStrings.uiEnterAValidNumber,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.activeGeneratesWeeklySessions),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              const SizedBox(height: AppSizes.s16),
              JbbButton(
                label: widget.template == null
                    ? AppStrings.uiAddClassTime
                    : AppStrings.saveChanges,
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

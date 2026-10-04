import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.date, required this.onChange});
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  @override
  Widget build(BuildContext context) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onChange(date.subtract(Duration(days: 7))),
              tooltip: AppStrings.previousWeek,
              icon: AppIcon(AppIcons.chevronLeft),
            ),
            Spacer(),
            Text(AppStrings.chooseYourTrainingDay),
            Spacer(),
            IconButton(
              onPressed: () => onChange(date.add(Duration(days: 7))),
              tooltip: AppStrings.nextWeek,
              icon: AppIcon(AppIcons.chevronRight),
            ),
          ],
        ),
        Row(
          children: List.generate(7, (i) {
            final day = monday.add(Duration(days: i)),
                selected = day.day == date.day && day.month == date.month;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: DateFormat.yMMMMEEEEd().format(day),
                child: InkWell(
                  onTap: () => onChange(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.s14),
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.s2),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.palette.accent
                          : context.palette.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEE').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: AppSizes.font10,
                            color: selected
                                ? AppColors.onAccent
                                : context.palette.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppSizes.s7),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: AppSizes.font20,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? AppColors.onAccent
                                : context.palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

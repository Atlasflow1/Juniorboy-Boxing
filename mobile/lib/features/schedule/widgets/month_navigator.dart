import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/widgets/app_icon.dart';

class MonthNavigator extends StatelessWidget {
  const MonthNavigator({super.key, required this.date, required this.onChange});
  final DateTime date;
  final ValueChanged<DateTime> onChange;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        tooltip: AppStrings.previousMonth,
        onPressed: () => onChange(DateTime(date.year, date.month - 1, 1)),
        icon: const AppIcon(AppIcons.chevronLeft),
      ),
      Text(
        DateFormat('MMMM yyyy').format(date),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      IconButton(
        tooltip: AppStrings.nextMonth,
        onPressed: () => onChange(DateTime(date.year, date.month + 1, 1)),
        icon: const AppIcon(AppIcons.chevronRight),
      ),
    ],
  );
}

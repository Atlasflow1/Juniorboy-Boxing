import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../providers/profile_provider.dart';

class InformationScreen extends ConsumerWidget {
  const InformationScreen({super.key, required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Text(
        text ??
            ref.watch(settingsProvider).value?['aboutText'] ??
            AppStrings.uiDisciplineBuildsChampionsTrainLearnAndGrowAt,
        style: const TextStyle(height: AppSizes.lineHeightLegal),
      ),
    ),
  );
}

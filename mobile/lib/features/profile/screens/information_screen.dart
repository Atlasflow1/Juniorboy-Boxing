import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';

class InformationScreen extends ConsumerWidget {
  const InformationScreen({super.key, required this.title, this.text});

  final String title;
  final String? text;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        text ??
            ref.watch(settingsProvider).value?['aboutText'] ??
            'Discipline builds champions. Train, learn and grow at Junior Boy Boxing.',
        style: const TextStyle(height: 1.7),
      ),
    ),
  );
}

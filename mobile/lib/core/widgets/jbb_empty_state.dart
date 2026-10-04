import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import 'app_icon.dart';

class JbbEmptyState extends StatelessWidget {
  const JbbEmptyState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const AppIcon(AppIcons.boxingGlove, size: 38, color: Colors.grey),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

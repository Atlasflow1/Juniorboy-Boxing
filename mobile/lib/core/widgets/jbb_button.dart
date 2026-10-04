import 'package:flutter/material.dart';
import '../resources/app_sizes.dart';

class JbbButton extends StatelessWidget {
  const JbbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? SizedBox(
            width: AppSizes.s22,
            height: AppSizes.s22,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.s2,
              color: Colors.white,
            ),
          )
        : Text(label),
  );
}

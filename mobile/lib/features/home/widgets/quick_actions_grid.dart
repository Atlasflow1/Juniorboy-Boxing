import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/widgets/jbb_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 1.45,
    mainAxisSpacing: 0,
    crossAxisSpacing: 12,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final item in [
        ('Book Class', AppIcons.boxingGlove, '/book'),
        ('Class Schedule', AppIcons.calendar, '/schedule'),
        ('Membership', AppIcons.crown, '/membership'),
        ('Gym Store', AppIcons.shoppingBag, '/store'),
        ('Reviews', AppIcons.star, '/reviews'),
        ('Contact', AppIcons.phone, '/contact'),
      ])
        JbbCard(
          onTap: () => context.safePush(item.$3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(item.$2, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                item.$1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
    ],
  );
}

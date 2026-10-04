import 'package:flutter/material.dart';
import '../../../../core/widgets/page_content.dart';
import '../widgets/membership_plans_section.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const PageContent(children: [MembershipPlansSection()]);
}

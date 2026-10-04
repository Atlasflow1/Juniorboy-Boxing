import 'package:flutter/material.dart';
import '../../../core/widgets/page_content.dart';
import '../widgets/membership_plans_section.dart';

/// No longer in the bottom nav — plan selection now lives on Home — but
/// kept reachable for deep links and the "add sessions" redirect from
/// booking when a member is out of credits.
class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const PageContent(children: [MembershipPlansSection()]);
}

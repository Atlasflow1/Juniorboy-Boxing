import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/services/stripe_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../providers/membership_provider.dart';
import '../widgets/plan_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Plan selection + purchase flow, shared between the Home screen (where it
/// now lives per the member's session-count request) and the standalone
/// `/membership` route kept around for deep links and redirects.
class MembershipPlansSection extends ConsumerStatefulWidget {
  const MembershipPlansSection({super.key});
  @override
  ConsumerState<MembershipPlansSection> createState() => _MembershipPlansState();
}

class _MembershipPlansState extends ConsumerState<MembershipPlansSection> {
  String selected = 'ten';
  final stripe = StripeService();
  bool busy = false;
  Future<void> purchase() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) showMessage(context, 'Signed in. Complete your profile, then choose your plan.');
        return;
      }
      final profile = (await FirebaseFirestore.instance.doc('users/${authUser.uid}').get()).data();
      if (!mounted) return;
      if (profile == null || !isProfileComplete(profile)) {
        final completed = await context.push<bool>('/complete-profile');
        if (completed != true || !mounted) return;
      }
      final message = await stripe.purchase(selected);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) { showMessage(context, e is FormatException ? e.message : friendlyError(e)); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Your Plan', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const _PlanMarquee(),
        const SizedBox(height: 16),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '${user['sessionsRemaining']} sessions remaining · ${user['sessionsReserved'] ?? 0} reserved',
            ),
          ),
        ref
            .watch(plansProvider)
            .when(
              data: (rows) {
                final plans = [...rows]
                  ..sort(
                    (a, b) => (a['sortOrder'] as num).compareTo(
                      b['sortOrder'] as num,
                    ),
                  );
                if (plans.isNotEmpty &&
                    !plans.any((p) => p['id'] == selected)) {
                  selected = plans.first['id'];
                }
                return Column(
                  children: [
                    for (final plan in plans)
                      PlanCard(
                        plan: plan,
                        selected: selected == plan['id'],
                        onTap: busy
                            ? () {}
                            : () => setState(() {
                                selected = plan['id'];
                              }),
                      ),
                    if (plans.isEmpty)
                      const JbbEmptyState(
                        message:
                            'Membership plans will appear here when available.',
                      ),
                    if (plans.any((p) => p['id'] == selected))
                      JbbButton(
                        label: 'Continue  →',
                        busy: busy,
                        onPressed: purchase,
                      ),
                  ],
                );
              },
              error: (e, s) => JbbEmptyState(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(plansProvider),
              ),
              loading: () => const JbbLoading(),
            ),
      ],
    );
  }
}

/// A thin, continuously auto-scrolling strip of plan highlights — replaces
/// the old static chip row with something that reads as "alive" without
/// competing for attention the way the plan cards below it do.
class _PlanMarquee extends StatefulWidget {
  const _PlanMarquee();
  @override
  State<_PlanMarquee> createState() => _PlanMarqueeState();
}

class _PlanMarqueeState extends State<_PlanMarquee>
    with SingleTickerProviderStateMixin {
  static const _items = ['Build Confidence', 'Get Stronger', 'Real Progress'];
  final scrollController = ScrollController();
  late final ticker = createTicker(_onTick);
  double offset = 0;

  void _onTick(Duration elapsed) {
    offset += 0.5;
    if (scrollController.hasClients) scrollController.jumpTo(offset);
  }

  @override
  void initState() {
    super.initState();
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 1000000,
        itemBuilder: (context, i) => Center(
          child: Text(
            _items[i % _items.length],
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        separatorBuilder: (context, i) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Icon(Icons.circle, size: 4, color: AppColors.muted),
          ),
        ),
      ),
    ),
  );
}

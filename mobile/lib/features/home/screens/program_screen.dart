import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/programs.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/services/stripe_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../membership/providers/membership_provider.dart';
import '../../membership/widgets/plan_card.dart';
import '../../auth/providers/auth_provider.dart';

const _programDescriptions = <String, String>{
  'boxing':
      'Build stance, footwork, defense and punching technique with focused coaching. Progress from fundamentals to more advanced drills at your level.',
  'fitness':
      'Improve general fitness through cardio, mobility and whole-body exercises adapted to your starting level.',
  'strength':
      'Develop strength, endurance and movement quality through progressive resistance work and conditioning drills.',
  'weight-loss':
      'Build consistent exercise habits with structured activity and conditioning. Results vary; training does not guarantee weight loss or replace medical or nutritional care.',
  'self-defense':
      'Practice awareness, positioning, movement and defensive fundamentals. Training cannot guarantee safety in a real confrontation.',
};

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  final stripe = StripeService();
  String? selected;
  bool busy = false;

  Future<void> purchase() async {
    final chosenPlan = selected;
    if (busy || chosenPlan == null || chosenPlan.isEmpty) {
      if (mounted && selected == null) {
        showMessage(context, 'Choose a plan to continue.');
      }
      return;
    }

    setState(() => busy = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) {
          showMessage(context, 'Signed in. Complete your profile, then choose your plan.');
        }
        return;
      }
      final profile = (await FirebaseFirestore.instance.doc('users/${authUser.uid}').get()).data();
      if (!mounted) return;
      if (profile == null || !isProfileComplete(profile)) {
        final completed = await context.push<bool>('/complete-profile');
        if (completed != true || !mounted) return;
      }
      final message = await stripe.purchase(chosenPlan);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) {
        showMessage(context, e is FormatException ? e.message : friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = Programs.categories[widget.id] ?? 'Program';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _programDescriptions[widget.id] ?? 'Contact the gym for program details.',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 8),
          const Text(
            'Availability and suitability are confirmed by the gym.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          JbbButton(
            label: 'View Available Sessions',
            onPressed: () => context.go('/schedule?program=${widget.id}'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.safePush('/contact'),
            child: const Text('Ask the Coach'),
          ),
          const SizedBox(height: 24),
          Text(
            'Subscribe to $title',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ref
              .watch(plansProvider)
              .when(
                data: (rows) {
                  final plans = rows.where((p) {
                    final category = p['category'] as String?;
                    return category == widget.id ||
                        category == null ||
                        category.isEmpty ||
                        category == 'general';
                  }).toList()..sort(
                    (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                      b['sortOrder'] as num? ?? 0,
                    ),
                  );
                  if (plans.isEmpty) {
                    return const JbbEmptyState(
                      message: 'Plans for this program will appear here when available.',
                    );
                  }

                  final effectiveSelected = plans.any(
                        (plan) => plan['id'] == selected,
                      )
                      ? selected
                      : plans.first['id'] as String?;

                  return Column(
                    children: [
                      for (final plan in plans)
                        PlanCard(
                          plan: plan,
                          selected: effectiveSelected == plan['id'],
                          onTap: busy
                              ? () {}
                              : () => setState(() => selected = plan['id']),
                        ),
                      const SizedBox(height: 8),
                      JbbButton(
                        label: 'Continue  →',
                        busy: busy,
                        onPressed: effectiveSelected == null ? null : purchase,
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
      ),
    );
  }
}

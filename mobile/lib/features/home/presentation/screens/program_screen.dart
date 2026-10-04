import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/programs.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../../../../core/widgets/jbb_empty_state.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../membership/presentation/providers/membership_provider.dart';
import '../../../membership/presentation/widgets/plan_card.dart';

const _programDescriptions = <String, String>{
  'boxing': AppStrings.uiBuildStanceFootworkDefenseAndPunchingTechniqueWith,
  'fitness': AppStrings.uiImproveGeneralFitnessThroughCardioMobilityAndWhole,
  'strength':
      AppStrings.uiDevelopStrengthEnduranceAndMovementQualityThroughProgressive,
  'weight-loss':
      AppStrings.uiBuildConsistentExerciseHabitsWithStructuredActivityAnd,
  'self-defense': AppStrings
      .uiPracticeAwarenessPositioningMovementAndDefensiveFundamentalsTraining,
};

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  String? selected;
  bool busy = false;

  Future<void> purchase() async {
    final chosenPlan = selected;
    if (busy || chosenPlan == null || chosenPlan.isEmpty) {
      if (mounted && selected == null) {
        showMessage(context, AppStrings.chooseAPlanToContinue);
      }
      return;
    }

    setState(() => busy = true);
    try {
      final authUser = ref.read(authRepositoryProvider).currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) {
          showMessage(
            context,
            AppStrings.signedInCompleteYourProfileThenChoose,
          );
        }
        return;
      }
      final profile = await ref.read(userRepositoryProvider).fetchProfile();
      if (!mounted) return;
      if (profile == null || !profile.isProfileComplete) {
        final completed = await context.push<bool>(AppRoutes.completeProfile);
        if (completed != true || !mounted) return;
      }
      final message = await ref
          .read(membershipRepositoryProvider)
          .purchase(chosenPlan);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          e is FormatException ? e.message : friendlyError(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = Programs.categories[widget.id] ?? AppStrings.program;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.s24),
        children: [
          Text(
            _programDescriptions[widget.id] ??
                AppStrings.uiContactTheGymForProgramDetails,
            style: TextStyle(
              fontSize: AppSizes.font16,
              height: AppSizes.lineHeightDescription,
            ),
          ),
          SizedBox(height: AppSizes.s8),
          Text(
            AppStrings.uiAvailabilityAndSuitabilityAreConfirmedByTheGym,
            style: TextStyle(
              color: context.palette.textSecondary,
              fontSize: AppSizes.font13,
            ),
          ),
          SizedBox(height: AppSizes.s24),
          JbbButton(
            label: AppStrings.viewAvailableSessions,
            onPressed: () =>
                context.safeNavigate(AppRoutes.schedule(programId: widget.id)),
          ),
          SizedBox(height: AppSizes.s12),
          TextButton(
            onPressed: () => context.safeNavigate(AppRoutes.contact),
            child: Text(AppStrings.askTheCoach),
          ),
          SizedBox(height: AppSizes.s24),
          Text(
            'Subscribe to $title',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: AppSizes.s12),
          ref
              .watch(plansProvider)
              .when(
                data: (rows) {
                  final plans =
                      rows.where((p) {
                          final category = p.category;
                          return category == widget.id ||
                              category == null ||
                              category.isEmpty ||
                              category == 'general';
                        }).toList()
                        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                  if (plans.isEmpty) {
                    return JbbEmptyState(
                      message:
                          AppStrings.uiPlansForThisProgramWillAppearHereWhen,
                    );
                  }

                  final effectiveSelected =
                      plans.any((plan) => plan.id == selected)
                      ? selected
                      : plans.first.id;

                  return Column(
                    children: [
                      for (final plan in plans)
                        PlanCard(
                          plan: plan,
                          selected: effectiveSelected == plan.id,
                          onTap: busy
                              ? () {}
                              : () => setState(() => selected = plan.id),
                        ),
                      SizedBox(height: AppSizes.s8),
                      JbbButton(
                        label: AppStrings.continueAction,
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
                loading: () => JbbLoading(),
              ),
        ],
      ),
    );
  }
}

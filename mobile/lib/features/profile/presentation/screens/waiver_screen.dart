import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/nav_debounce.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/jbb_button.dart';
import '../providers/profile_provider.dart';
import '../../domain/waiver.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WaiverScreen extends ConsumerStatefulWidget {
  const WaiverScreen({super.key});
  @override
  ConsumerState<WaiverScreen> createState() => _WaiverState();
}

class _WaiverState extends ConsumerState<WaiverScreen> {
  final name = TextEditingController();
  bool adult = false, agree = false, guardian = false, busy = false;
  String? version;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> sign(Waiver waiver) async {
    if (!adult || !agree || name.text.trim().length < 2) {
      showMessage(context, AppStrings.enterYourNameAndConfirmBothAgreements);
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(waiverRepositoryProvider)
          .accept(
            version: waiver.version,
            signerName: name.text.trim(),
            guardian: guardian,
            adult: adult,
            agree: agree,
          );
      if (mounted) {
        showMessage(context, AppStrings.yourAgreementHasBeenRecorded);
      }
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.waiverDisclaimer)),
      body: ref
          .watch(waiverProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text(friendlyError(e))),
            data: (waiver) {
              if (version != waiver.version) {
                version = waiver.version;
                adult = false;
                agree = false;
              }
              final published = waiver.published;
              final accepted =
                  published &&
                  profile?.waiverVersion == waiver.version &&
                  profile?.waiverParticipantName == profile?.childName.trim() &&
                  profile?.waiverParticipantAge == profile?.childAge;
              return ListView(
                padding: const EdgeInsets.all(AppSizes.s24),
                children: [
                  if (!published)
                    const Text(
                      AppStrings.uiDraftSigningOpensAfterTheGymApprovesAnd,
                      style: TextStyle(color: AppColors.amber),
                    ),
                  const SizedBox(height: AppSizes.s16),
                  Text(
                    published ? waiver.body! : AppStrings.waiver,
                    style: const TextStyle(height: AppSizes.lineHeightLegal),
                  ),
                  const SizedBox(height: AppSizes.s24),
                  if (accepted)
                    const Text(AppStrings.yourAgreementToThisVersionIsRecorded)
                  else if (published &&
                      ref
                              .read(authRepositoryProvider)
                              .currentUser
                              ?.isAnonymous ==
                          false) ...[
                    Text(
                      'Participant: ${profile?.childName ?? ''} · Age: ${profile?.childAge ?? ''}',
                    ),
                    TextButton(
                      onPressed: () => context.safeNavigate(AppRoutes.profile),
                      child: const Text(AppStrings.editParticipantDetails),
                    ),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: AppStrings.yourFullLegalName,
                      ),
                      maxLength: 100,
                    ),
                    CheckboxListTile(
                      value: guardian,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => guardian = v ?? false),
                      title: const Text(
                        AppStrings.uiIAmTheParentOrLegalGuardianRequired,
                      ),
                    ),
                    CheckboxListTile(
                      value: adult,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => adult = v ?? false),
                      title: const Text(
                        AppStrings.uiIAm18OrOlderAndAuthorizedTo,
                      ),
                    ),
                    CheckboxListTile(
                      value: agree,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => agree = v ?? false),
                      title: const Text(
                        AppStrings.uiIReadUnderstandAndAgreeToThisVersion,
                      ),
                    ),
                    JbbButton(
                      label: AppStrings.recordMyAgreement,
                      busy: busy,
                      onPressed: () => sign(waiver),
                    ),
                  ] else if (published)
                    const Text(AppStrings.uiSignInWithARegisteredAccountToSign),
                ],
              );
            },
          ),
    );
  }
}

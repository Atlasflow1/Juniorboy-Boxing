import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/resources/app_sizes.dart';
import '../../../../core/resources/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/jbb_loading.dart';
import '../../../account/models/user_model.dart';
import '../providers/session_provider.dart';

/// Shown when a member taps a session card's joined-avatars stack — lists
/// every joined member's name and photo in full.
class SessionMembersScreen extends ConsumerWidget {
  const SessionMembersScreen({super.key, required this.uids});
  final List<String> uids;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.uiJoinedMembers)),
    body: FutureBuilder<List<UserModel>>(
      future: ref.read(sessionRepositoryProvider).fetchMembers(uids),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const JbbLoading();
        final members = snapshot.data!;
        if (members.isEmpty) {
          return Center(
            child: Text(
              AppStrings.uiNoOneHasJoinedYet,
              style: TextStyle(color: context.palette.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.s16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: context.palette.accentTint,
                backgroundImage: member.profilePicUrl != null
                    ? CachedNetworkImageProvider(member.profilePicUrl!)
                    : null,
                child: member.profilePicUrl == null
                    ? AppIcon(AppIcons.user, color: context.palette.accent)
                    : null,
              ),
              title: Text(member.fullName),
            );
          },
        );
      },
    ),
  );
}

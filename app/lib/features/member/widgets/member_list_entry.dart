import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class _MemberListInnerSkeleton extends StatelessWidget {
  const _MemberListInnerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Skeletonizer(
        child: ActerAvatar(
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: L10n.of(context).noIdGiven,
            ),
            size: 18,
          ),
        ),
      ),
      title: Skeletonizer(
        child: Text(
          L10n.of(context).noId,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: Skeletonizer(
        child: Text(
          L10n.of(context).noId,
          style: Theme.of(context).textTheme.labelLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class MemberListEntry extends ConsumerWidget {
  final String memberId;
  final String roomId;
  final Member? myMembership;
  final bool isShowActions;

  const MemberListEntry({
    super.key,
    required this.memberId,
    required this.roomId,
    this.myMembership,
    this.isShowActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member =
        ref.watch(memberProvider((userId: memberId, roomId: roomId)));
    return member.when(
      data: (data) => _MemberListEntryInner(
        userId: memberId,
        roomId: roomId,
        member: data,
        isShowActions: isShowActions,
      ),
      error: (e, s) => Text(L10n.of(context).errorLoadingProfile(e)),
      loading: () => const _MemberListInnerSkeleton(),
    );
  }
}

class _MemberListEntryInner extends ConsumerWidget {
  final Member member;
  final String userId;
  final String roomId;
  final bool isShowActions;

  const _MemberListEntryInner({
    required this.userId,
    required this.member,
    required this.roomId,
    this.isShowActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberStatus = member.membershipStatusStr();
    Widget? trailing;
    if (memberStatus == 'Admin') {
      trailing = const Tooltip(
        message: 'Admin',
        child: Icon(Atlas.crown_winner_thin),
      );
    } else if (memberStatus == 'Mod') {
      trailing = const Tooltip(
        message: 'Moderator',
        child: Icon(Atlas.shield_star_win_thin),
      );
    }

    final avatarInfo =
        ref.watch(memberAvatarInfoProvider((userId: userId, roomId: roomId)));

    return ListTile(
      onTap: () async {
        if (context.mounted) {
          await showMemberInfoDrawer(
            context: context,
            roomId: roomId,
            memberId: userId,
            isShowActions: isShowActions,
          );
        }
      },
      leading: ActerAvatar(
        options: AvatarOptions.DM(
          avatarInfo,
          size: 18,
        ),
      ),
      title: Text(
        avatarInfo.displayName ?? userId,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: avatarInfo.displayName != null
          ? Text(
              userId,
              style: Theme.of(context).textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
    );
  }
}

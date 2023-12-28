import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarBuilder extends ConsumerWidget {
  late RoomMemberQuery query;

  AvatarBuilder({
    Key? key,
    userId,
    roomId,
  }) : super(key: key) {
    query = RoomMemberQuery(roomId, userId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberProfile = ref.watch(roomMemberProvider(query));
    return memberProfile.when(
      data: (profile) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: query.userId,
              displayName: profile.displayName ?? query.userId,
              avatar: profile.getAvatarImage(),
            ),
            size: 14,
          ),
        );
      },
      error: (e, st) {
        debugPrint('ERROR loading avatar due to $e');
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo:
                AvatarInfo(uniqueId: query.userId, displayName: query.userId),
            size: 14,
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo:
              AvatarInfo(uniqueId: query.userId, displayName: query.userId),
          size: 14,
        ),
      ),
    );
  }
}

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatTypingEventProvider = StreamProvider.autoDispose
    .family<List<String>, String>((ref, roomId) async* {
      final client = await ref.watch(alwaysClientProvider.future);
      final userId = ref.watch(myUserIdStrProvider);
      await for (final event in client.subscribeToTypingEventStream(roomId)) {
        yield event
            .userIds()
            .toList()
            .map((i) => i.toString())
            .where((i) => i != userId)
            .toList();
      }
    });

final chatTypingUsersAvatarInfoProvider =
    Provider.family<List<AvatarInfo>, String>((ref, roomId) {
      final typingUsers =
          ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
      if (typingUsers == null || typingUsers.isEmpty) return [];
      return typingUsers
          .map(
            (userId) => ref.watch(
              memberAvatarInfoProvider((roomId: roomId, userId: userId)),
            ),
          )
          .toList();
    });

final chatTypingUsersDisplayNameProvider = Provider.family<
  List<String>,
  String
>((ref, roomId) {
  final typingUsers = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
  if (typingUsers == null || typingUsers.isEmpty) return [];
  return typingUsers
      .map(
        (userId) =>
            ref
                .watch(
                  memberDisplayNameProvider((roomId: roomId, userId: userId)),
                )
                .valueOrNull ??
            userId,
      )
      .toList();
});

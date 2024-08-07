import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::providers::suggested');

// Whether or not to prompt the user about the suggested rooms.
final shouldShowSuggestedProvider =
    FutureProvider.family<bool, String>((ref, spaceId) async {
  final room = await ref.watch(maybeRoomProvider(spaceId).future);
  if (room == null) {
    return false;
  }
  try {
    if (await room.userHasSeenSuggested()) {
      return false;
    }

    final suggestedRooms =
        await ref.watch(suggestedRoomsProvider(spaceId).future);
    // only if we really have some remote rooms that the user is suggested and not yet in
    return suggestedRooms.chats.isNotEmpty || suggestedRooms.spaces.isNotEmpty;
  } catch (error, stack) {
    _log.severe('Fetching suggestions showing failed', error, stack);
    return false;
  }
});

typedef SuggestedRooms = ({
  List<SpaceHierarchyRoomInfo> spaces,
  List<SpaceHierarchyRoomInfo> chats
});

final suggestedRoomsProvider =
    FutureProvider.family<SuggestedRooms, String>((ref, roomId) async {
  final chats = await ref.watch(remoteChatRelationsProvider(roomId).future);
  final spaces =
      await ref.watch(remoteSubspaceRelationsProvider(roomId).future);
  return (
    chats: chats.where((r) => r.suggested()).toList(),
    spaces: spaces.where((r) => r.suggested()).toList()
  );
});

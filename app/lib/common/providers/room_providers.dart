/// Get the relations of the given SpaceId.  Throws
library;

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::common::room_providers');

class RoomItem {
  final Member? membership;
  final Room? room;
  final String roomId;
  final AvatarInfo avatarInfo;
  final List<Member> activeMembers;

  const RoomItem({
    this.membership,
    this.room,
    required this.roomId,
    required this.activeMembers,
    required this.avatarInfo,
  });
}

class RoomNotFound extends Error {}

/// Attempts to map a roomId to the room, but could come back empty (null) rather than throw.
/// keeps up to date with underlying client even if the room wasn't found initially,
final maybeRoomProvider =
    AsyncNotifierProvider.family<AsyncMaybeRoomNotifier, Room?, String>(
  () => AsyncMaybeRoomNotifier(),
);

/// Provider the profile data of a the given room, keeps up to date with underlying client
// final roomProfileDataProvider =
//     FutureProvider.autoDispose.family<AvatarInfo, String>((ref, roomId) async {
//   final room = await ref.watch(maybeRoomProvider(roomId).future);
//   if (room == null) {
//     throw RoomNotFound;
//   }

//   final profile = room.getProfile();
//   OptionString displayName = await profile.getDisplayName();
//   try {
//     final avatar = (await profile.getAvatar(null)).data();
//     _log.info('$roomId : hasAvatar: ${avatar != null}');
//     return ProfileData(displayName.text(), avatar);
//   } catch (error) {
//     _log.severe('Loading avatar for $roomId failed', error);
//     return ProfileData(displayName.text(), null);
//   }
// });

/// gives current visibility state of space, return empty if no space is found
final roomVisibilityProvider = FutureProvider.family
    .autoDispose<RoomVisibility?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  final joinRule = room.joinRuleStr();
  switch (joinRule) {
    case 'public':
      return RoomVisibility.Public;
    case 'restricted':
      return RoomVisibility.SpaceVisible;
    case 'invite':
      return RoomVisibility.Private;
    default:
      _log.warning('Unsupported joinRule for $roomId: $joinRule');
      throw 'Unsupported joinRule $joinRule';
  }
});

/// Get the members invited of a given roomId the user knows about. Errors
/// if the room isn't found. Stays up to date with underlying client data
/// if a room was found.
final roomInvitedMembersProvider = FutureProvider.autoDispose
    .family<List<Member>, String>((ref, roomIdOrAlias) async {
  final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
  if (room == null || !room.isJoined()) {
    return [];
  }
  final members = await room.invitedMembers();
  return members.toList();
});

/// Get the RoomItem of the given sapceId filled in brief form
/// (only spaceProfileData, no activeMembers) with Membership.
/// Stays up to date with underlying client info
final briefRoomItemWithMembershipProvider =
    FutureProvider.autoDispose.family<RoomItem, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    throw RoomNotFound;
  }

  final avatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
  return RoomItem(
    roomId: roomId,
    room: room,
    membership: room.isJoined() ? await room.getMyMembership() : null,
    activeMembers: [],
    avatarInfo: avatarInfo,
  );
});

final roomSearchValueProvider =
    StateProvider.autoDispose<String?>((ref) => null);

typedef _RoomIdAndName = (String, String?);

final _briefGroupChatsWithName =
    FutureProvider.autoDispose<List<_RoomIdAndName>>((ref) async {
  final chatList =
      ref.watch(chatsProvider).where((element) => (!element.isDm())).toList();

  List<_RoomIdAndName> items = [];
  for (final convo in chatList) {
    final roomId = convo.getRoomIdStr();
    final room = await ref.watch(maybeRoomProvider(roomId).future);

    if (room != null) {
      final profile = room.getProfile();
      OptionString displayName = await profile.getDisplayName();
      items.add((roomId, displayName.text()));
    }
  }
  return items;
});

final roomSearchedChatsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final allRoomList = await ref.watch(_briefGroupChatsWithName.future);
  final foundRooms = List<String>.empty(growable: true);
  final searchValue = ref.watch(roomSearchValueProvider);

  if (searchValue == null || searchValue.isEmpty) {
    return allRoomList.map((i) {
      return i.$1;
    }).toList();
  }

  final loweredSearchValue = searchValue.toLowerCase();

  for (final item in allRoomList) {
    if (item.$1.toLowerCase().contains(loweredSearchValue) ||
        (item.$2 ?? '').toLowerCase().contains(loweredSearchValue)) {
      foundRooms.add(item.$1);
    }
  }

  return foundRooms;
});

/// If the room exists, this returns its space relations
/// Stays up to date with underlying client data if a room was found.
final spaceRelationsProvider =
    FutureProvider.family<SpaceRelations?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return await room.spaceRelations();
});

final parentIdsProvider =
    FutureProvider.family<List<String>, String>((ref, roomId) async {
  try {
    // FIXME: we should get only the parent Ids from the underlying SDK
    final relations = await ref.watch(spaceRelationsProvider(roomId).future);
    if (relations == null) {
      return [];
    }

    // Collect all parents: mainParent and otherParents
    List<String> allParents = [];
    final mainParent = relations.mainParent();
    if (mainParent != null) {
      allParents.add(mainParent.roomId().toString());
    }
    allParents
        .addAll(relations.otherParents().map((p) => p.roomId().toString()));
    return allParents;
  } catch (e) {
    _log.warning('Failed to load parent ids for $roomId: $e');
    return [];
  }
});

/// Caching the Profile of each Room
final _roomProfileProvider =
    FutureProvider.family<RoomProfile, String>((ref, roomId) {
  final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
  if (room == null) {
    throw RoomNotFound;
  }

  return room.getProfile();
});

/// Caching the name of each Room
final roomDisplayNameProvider =
    FutureProvider.family<String?, String>((ref, roomId) async {
  try {
    final profile = await ref.watch(_roomProfileProvider(roomId).future);
    return (await profile.getDisplayName()).text();
  } on RoomNotFound {
    return null;
  }
});

/// Caching the MemoryImage of each room
final _roomAvatarProvider =
    FutureProvider.family<MemoryImage?, String>((ref, roomId) async {
  try {
    final sdk = await ref.watch(sdkProvider.future);
    final thumbsize = sdk.api.newThumbSize(48, 48);

    final avatar = (await (await ref.watch(_roomProfileProvider(roomId).future))
            .getAvatar(thumbsize))
        .data();
    if (avatar != null) {
      return MemoryImage(avatar.asTypedList());
    }
    return null;
  } on RoomNotFound {
    return null;
  }
});

/// Provide the AvatarInfo for each room. Update internally accordingly
final roomAvatarInfoProvider =
    Provider.family<AvatarInfo, String>((ref, roomId) {
  final fallback = AvatarInfo(uniqueId: roomId);

  final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
  if (room == null) {
    return fallback;
  }

  final displayName = ref.watch(roomDisplayNameProvider(roomId)).valueOrNull;
  final avatarData = ref.watch(_roomAvatarProvider(roomId)).valueOrNull;

  return AvatarInfo(
    uniqueId: roomId,
    displayName: displayName,
    avatar: avatarData,
  );
});

/// get the [AvatarInfo] list of all the parents
final parentAvatarInfosProvider =
    FutureProvider.family<List<AvatarInfo>?, String>((ref, roomId) async {
  final parents = await ref.watch(parentIdsProvider(roomId).future);
  // watch each one individually
  return parents.map((e) => ref.watch(roomAvatarInfoProvider(e))).toList();
});

final joinRulesAllowedRoomsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return [];
  }
  return room.restrictedRoomIdsStr().map((e) => e.toDartString()).toList();
});

/// Get the List of related of the spaces for the space. Errors if the space or any
/// related space isn't found. Stays up  to date with underlying client data if
/// a space was found.
final relatedSpacesProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownSubspaces;
});

/// Get the user's membership for a specific space based off the spaceId
/// will throw if the client doesn't kow the space
final roomMembershipProvider = FutureProvider.family<Member?, String>(
  (ref, roomId) async {
    final room = await ref.watch(maybeRoomProvider(roomId).future);
    if (room == null || !room.isJoined()) {
      return null;
    }
    return await room.getMyMembership();
  },
);

/// Get the locally configured RoomNotificationsStatus for this room
final roomNotificationStatusProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return room.notificationMode();
});

/// Get the default RoomNotificationsStatus for this room type
final roomDefaultNotificationStatusProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final room = await ref.watch(maybeRoomProvider(roomId).future);
  if (room == null) {
    return null;
  }
  return room.defaultNotificationMode();
});

/// Get the default RoomNotificationsStatus for this room type
final roomIsMutedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, roomId) async {
  final status = await ref.watch(roomNotificationStatusProvider(roomId).future);
  return status == 'muted';
});

final memberProvider =
    FutureProvider.autoDispose.family<Member, MemberInfo>((ref, query) async {
  final room = await ref.watch(maybeRoomProvider(query.roomId).future);
  if (room == null) {
    throw RoomNotFound;
  }
  return await room.getMember(query.userId);
});

final _memberProfileProvider = FutureProvider.autoDispose
    .family<UserProfile, MemberInfo>((ref, query) async {
  final member = await ref.watch(memberProvider(query).future);
  return member.getProfile();
});

final memberDisplayNameProvider =
    FutureProvider.autoDispose.family<String?, MemberInfo>((ref, query) async {
  return ref.watch(_memberProfileProvider(query)).valueOrNull?.getDisplayName();
});

/// Caching the MemoryImage of each room
final _memberAvatarProvider = FutureProvider.autoDispose
    .family<MemoryImage?, MemberInfo>((ref, query) async {
  final sdk = await ref.watch(sdkProvider.future);

  final thumbsize = sdk.api.newThumbSize(48, 48);
  final profile = await ref.watch(_memberProfileProvider(query).future);
  // use .data() consumes the value so we keep it stored, any further call to .data()
  // comes back empty as the data was consumed.
  final avatar = (await profile.getAvatar(thumbsize)).data();
  if (avatar != null) {
    return MemoryImage(avatar.asTypedList());
  }
  return null;
});

final memberAvatarInfoProvider =
    Provider.autoDispose.family<AvatarInfo, MemberInfo>((ref, query) {
  final displayName = ref.watch(memberDisplayNameProvider(query)).valueOrNull;
  final avatarData = ref.watch(_memberAvatarProvider(query)).valueOrNull;

  return AvatarInfo(
    uniqueId: query.userId,
    displayName: displayName,
    avatar: avatarData,
  );
});

final membersIdsProvider =
    FutureProvider.family<List<String>, String>((ref, roomIdOrAlias) async {
  final room = await ref.watch(maybeRoomProvider(roomIdOrAlias).future);
  if (room == null) {
    throw RoomNotFound;
  }
  final members = await room.activeMembersIds();
  return asDartStringList(members);
});

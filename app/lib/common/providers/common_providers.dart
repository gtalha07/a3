import 'dart:async';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/network_notifier.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        Account,
        Conversation,
        FfiListConversation,
        Member,
        OptionText,
        UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Network/Connectivity Providers
final networkAwareProvider =
    StateNotifierProvider<NetworkStateNotifier, NetworkStatus>(
  (ref) => NetworkStateNotifier(),
);

// Loading Providers
final loadingProvider = StateProvider<bool>((ref) => false);

// Account Profile Providers
class AccountProfile {
  final Account account;
  final ProfileData profile;
  const AccountProfile(this.account, this.profile);
}

Future<ProfileData> getProfileData(Account account) async {
  // FIXME: how to get informed about updates!?!
  final displayName = await account.displayName();
  final avatar = await account.avatar();
  return ProfileData(displayName.text(), avatar.data());
}

final accountProvider = FutureProvider((ref) async {
  final client = ref.watch(clientProvider)!;
  return client.account();
});

final accountProfileProvider = FutureProvider((ref) async {
  final account = await ref.watch(accountProvider.future);
  final profile = await getProfileData(account);
  return AccountProfile(account, profile);
});

// Chat Providers
final chatProfileDataProvider =
    FutureProvider.family<ProfileData, Conversation>((ref, chat) async {
  // FIXME: how to get informed about updates!?!
  final profile = chat.getProfile();
  final displayName = await profile.getDisplayName();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName.text(), null);
  }
  final avatar = await profile.getThumbnail(48, 48);
  return ProfileData(displayName.text(), avatar.data());
});

final chatsProvider = FutureProvider<List<Conversation>>((ref) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: how to get informed about updates!?!
  final chats = await client.conversations();
  return chats.toList();
});

final chatProvider =
    FutureProvider.family<Conversation, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(clientProvider)!;
  // FIXME: fallback to fetching a public data, if not found
  return await client.conversation(roomIdOrAlias);
});

final chatMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, roomIdOrAlias) async {
  final chat = ref.watch(chatProvider(roomIdOrAlias)).requireValue;
  final members = await chat.activeMembers();
  return members.toList();
});

// chats stream provider
final chatStreamProvider =
    StreamProvider.autoDispose<List<JoinedRoom>>((ref) async* {
  final client = ref.watch(clientProvider)!;
  late List<JoinedRoom> convos = [];
  StreamSubscription<FfiListConversation>? _convosSubscription;
  _convosSubscription = client.conversationsRx().listen((event) {
    for (var room in event.toList()) {
      JoinedRoom r = JoinedRoom(
        id: room.getRoomIdStr(),
        conversation: room,
        latestMessage: room.latestMessage(),
      );
      convos.add(r);
    }
  });
  ref.onDispose(() => _convosSubscription!.cancel());
  yield convos;
});

final relatedChatsProvider = FutureProvider.autoDispose
    .family<List<JoinedRoom>, String>((ref, spaceId) async {
  List<JoinedRoom> conversations = [];
  ref
      .watch(chatStreamProvider)
      .whenData((value) => conversations.addAll(value));
  final relatedSpaces = await ref.watch(spaceRelationsProvider(spaceId).future);
  final List<JoinedRoom> chats = [];
  final children = relatedSpaces.children();
  for (JoinedRoom room in conversations) {
    for (final related in children) {
      if (related.targetType() == 'ChatRoom') {
        final roomId = related.roomId().toString();
        if (room.id == roomId) {
          final joinedRoom = JoinedRoom(
            id: room.id,
            conversation: room.conversation,
            latestMessage: room.latestMessage,
          );
          chats.add(joinedRoom);
        }
      }
    }
  }
  return List<JoinedRoom>.from(chats);
});

// Member Providers
final memberProfileProvider =
    FutureProvider.family.autoDispose<ProfileData, Member>((ref, member) async {
  UserProfile profile = member.getProfile();
  OptionText displayName = await profile.getDisplayName();
  final avatar = await profile.getAvatar();
  return ProfileData(displayName.text(), avatar.data());
});

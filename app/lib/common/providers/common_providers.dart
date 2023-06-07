import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/notifiers/network_notifier.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Account, Conversation, DispName, Member, UserProfile;
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
  final name = await account.displayName();
  final avatar = await account.avatar();
  return ProfileData(name, avatar);
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
  final name = await profile.getDisplayName();
  final displayName = name.text() ?? chat.getRoomId().toString();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName, null);
  }
  final avatar = await profile.getThumbnail(48, 48);
  return ProfileData(displayName, avatar);
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

final relatedChatsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, spaceId) async {
  final client = ref.watch(clientProvider)!;
  final relatedSpaces = ref.watch(spaceRelationsProvider(spaceId)).requireValue;
  final chats = [];
  final children = relatedSpaces.children();
  for (final related in children) {
    if (related.targetType() == 'ChatRoom') {
      final roomId = related.roomId().toString();
      final room = await client.conversation(roomId);
      chats.add(room);
    }
  }
  return List<Conversation>.from(chats);
});

// Member Providers
final memberProfileProvider =
    FutureProvider.family.autoDispose<ProfileData, Member>((ref, member) async {
  UserProfile profile = member.getProfile();
  DispName dispName = await profile.getDisplayName();
  final avatar = await profile.getAvatar();
  return ProfileData(dispName.text(), avatar);
});
import 'dart:typed_data';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/invitations/providers/notifiers/invitation_manager_notifier.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final invitationsManagerProvider = FutureProvider(
  (ref) async => (await ref.watch(alwaysClientProvider.future)).invitations(),
);

final invitationsStates =
    AsyncNotifierProvider<InvitationManagerNotifier, InvitesState>(
      () => InvitationManagerNotifier(),
    );

final invitationListProvider = FutureProvider(
  (ref) async => (await ref.watch(invitationsStates.future)).rooms,
);

final invitationUserProfileProvider = FutureProvider.autoDispose
    .family<AvatarInfo?, RoomInvitation>((ref, invitation) async {
      UserProfile? user = invitation.senderProfile();
      if (user == null) {
        return null;
      }
      final userId = user.userId().toString();
      final displayName = user.displayName();
      final fallback = AvatarInfo(uniqueId: userId, displayName: displayName);
      final avatar = await user.getAvatar(null);
      final avatarData = avatar.data();

      if (!user.hasAvatar() || avatarData == null) {
        return fallback;
      }
      final data = MemoryImage(Uint8List.fromList(avatarData.asTypedList()));

      return AvatarInfo(
        uniqueId: userId,
        displayName: displayName,
        avatar: data,
      );
    });

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _MemberInfoDrawer extends StatelessWidget {
  final ProfileData memberProfile;
  final String memberId;
  final String roomId;
  const _MemberInfoDrawer({
    super.key,
    required this.memberProfile,
    required this.memberId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildAvatarUI(context),
            const SizedBox(height: 20),
            if (memberProfile.displayName != null) _buildDisplayName(context),
            const SizedBox(height: 20),
            _buildUserName(context),
            const SizedBox(height: 20),
            _buildMessageUser(),
            const SizedBox(height: 30),
            _actionMenuItem(
              context: context,
              iconData: Atlas.block_thin,
              title: 'Block User',
              withMenu: false,
            ),
            const SizedBox(height: 30),
          ],
          // _profileItem(
          //   key: MyProfilePage.displayNameKey,
          //   context: context,
          //   title: 'Display Name',
          //   subTitle: displayName,
          //   trailingIcon: Atlas.pencil_edit,
          //   onPressed: () => updateDisplayName(data, context, ref),
          // ),
          // const SizedBox(height: 20),
          // _profileItem(
          //   context: context,
          //   title: 'Username',
          //   subTitle: userId,
          //   trailingIcon: Atlas.pages,
          //   onPressed: () {
          //     Clipboard.setData(
          //       ClipboardData(text: userId),
          //     );
          //     customMsgSnackbar(
          //       context,
          //       'Username copied to clipboard',
          //     );
          //   },
          // ),
        ),
      ),
    );
  }

  Widget _buildAvatarUI(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await gotoFullProfile(context);
      },
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: memberId,
              avatar: memberProfile.getAvatarImage(),
              displayName: memberProfile.displayName,
            ),
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageUser() {
    return Consumer(
      builder: (context, ref, widget) {
        final client = ref.watch(alwaysClientProvider);
        final dmId = client.dmWithUser(memberId).text();
        if (dmId != null) {
          debugPrint('DM id; $dmId');
          return Center(
            child: OutlinedButton.icon(
              icon: const Icon(Atlas.chats_thin),
              onPressed: () async {
                context.pop();
                context.pushNamed(
                  Routes.chatroom.name,
                  pathParameters: {
                    'roomId': dmId,
                  },
                );
              },
              label: const Text('Message'),
            ),
          );
        } else {
          return Center(
            child: OutlinedButton.icon(
              icon: const Icon(Atlas.chats_thin),
              onPressed: () {
                context.pop();
                context.pushNamed(
                  Routes.createChat.name,
                  queryParameters: {
                    'userId': memberId,
                  },
                );
              },
              label: const Text('Start DM'),
            ),
          );
        }
      },
    );
  }

  Widget _buildDisplayName(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await gotoFullProfile(context);
      },
      child: Center(
        child: Text(memberProfile.displayName!), // FIXME: make this prettier
      ),
    );
  }

  Widget _buildUserName(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        context.pop(); // close the drawer
        Clipboard.setData(
          ClipboardData(
            text: memberId,
          ),
        );
        customMsgSnackbar(
          context,
          'Username copied to clipboard',
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(memberId), // FIXME: make this prettier
          const SizedBox(width: 5),
          const Icon(Icons.copy_outlined),
        ],
      ),
    );
  }

  Future<void> gotoFullProfile(BuildContext context) async {}
}

Widget _actionMenuItem({
  Key? key,
  required BuildContext context,
  required IconData iconData,
  Color? iconColor,
  required String title,
  TextStyle? titleStyles,
  String? subTitle,
  VoidCallback? onTap,
  bool enable = true,
  bool withMenu = true,
}) {
  return Card(
    child: ListTile(
      key: key,
      onTap: onTap,
      leading: Icon(
        iconData,
        color: enable ? iconColor : Theme.of(context).disabledColor,
      ),
      title: Text(
        title,
        style: titleStyles?.copyWith(
          color: enable ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: subTitle == null
          ? null
          : Text(
              subTitle,
              style: titleStyles?.copyWith(
                color: enable ? null : Theme.of(context).disabledColor,
              ),
            ),
      trailing: withMenu
          ? const Icon(
              Icons.keyboard_arrow_right_outlined,
            )
          : null,
    ),
  );
}

const Key memberInfoDrawer = Key('members-widgets-member-info-drawer');
Future<void> showMemberInfoDrawer({
  required BuildContext context,
  required ProfileData memberProfile,
  required String roomId,
  required String memberId,
  Key? key = memberInfoDrawer,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => _MemberInfoDrawer(
      key: key,
      roomId: roomId,
      memberId: memberId,
      memberProfile: memberProfile,
    ),
  );
}

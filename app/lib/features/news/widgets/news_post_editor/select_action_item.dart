import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class SelectActionItem extends StatelessWidget {
  final VoidCallback onShareEventSelected;
  final VoidCallback onSharePinSelected;
  final VoidCallback onShareTaskListSelected;
  final VoidCallback onShareLinkSelected;
  final VoidCallback onShareSpaceSelected;
  final VoidCallback onShareChatSelected;
  final VoidCallback onShareSuperInviteSelected;

  const SelectActionItem({
    super.key,
    required this.onShareEventSelected,
    required this.onSharePinSelected,
    required this.onShareTaskListSelected,
    required this.onShareLinkSelected,
    required this.onShareSpaceSelected,
    required this.onShareChatSelected,
    required this.onShareSuperInviteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.calendar_dots,
          actionName: L10n.of(context).eventShare,
          onTap: onShareEventSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.pin,
          actionName: L10n.of(context).sharePin,
          onTap: onSharePinSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.list,
          actionName: L10n.of(context).shareTaskList,
          onTap: onShareTaskListSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.link,
          actionName: L10n.of(context).shareLink,
          onTap: onShareLinkSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.team_group,
          actionName: L10n.of(context).shareSpace,
          onTap: onShareSpaceSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.chats,
          actionName: L10n.of(context).shareChat,
          onTap: onShareChatSelected,
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.ticket_coupon,
          actionName: L10n.of(context).shareSuperInvite,
          onTap: onShareSuperInviteSelected,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget actionItemUI({
    required BuildContext context,
    required IconData actionIcon,
    required String actionName,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(actionIcon),
      title: Text(actionName),
    );
  }
}

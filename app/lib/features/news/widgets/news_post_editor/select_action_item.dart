import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SelectActionItem extends StatelessWidget {
  final Function onShareEventSelected;
  final Function onSharePinSelected;

  const SelectActionItem({
    super.key,
    required this.onShareEventSelected,
    required this.onSharePinSelected,
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
          onTap: () => onShareEventSelected(),
        ),
        const SizedBox(height: 20),
        actionItemUI(
          context: context,
          actionIcon: Atlas.pin,
          actionName: L10n.of(context).sharePin,
          onTap: () => onSharePinSelected(),
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

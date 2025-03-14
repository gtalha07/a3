import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/deep_linking/actions/handle_deep_link_uri.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/util.dart';
import 'package:acter/features/deep_linking/widgets/item_preview_card.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReferenceDetailsItem extends ConsumerWidget {
  final RefDetails refDetails;
  final bool tapEnabled;
  final EdgeInsets? margin;

  const ReferenceDetailsItem({
    super.key,
    required this.refDetails,
    this.tapEnabled = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ObjectType? type = typeFromRefDetails(refDetails);
    return ItemPreviewCard(
      title:
          type == ObjectType.space || type == ObjectType.chat
              ? refDetails.roomDisplayName()
              : refDetails.title(),
      refType: type,
      onTap: tapEnabled ? () => onTap(context, ref, type) : null,
      margin: margin,
    );
  }

  void onTap(BuildContext context, WidgetRef ref, ObjectType? type) {
    final roomId = refDetails.roomIdStr();
    if (roomId == null) {
      EasyLoading.showError(
        L10n.of(context).noObjectAccess(refDetails.typeStr(), 'missing roomId'),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final serverNames = refDetails.viaServers().toDart();
    showRoomPreview(
      context: context,
      roomIdOrAlias: roomId,
      fallbackRoomDisplayName: refDetails.roomDisplayName(),
      serverNames: serverNames,
      onForward: (context, ref, room) async {
        handleDeepLinkUri(
          context: context,
          ref: ref,
          uri: Uri.parse(refDetails.generateInternalLink(false)),
        );
      },
      headerInfo:
          type != ObjectType.space && type != ObjectType.chat
              ? headerInfo(context)
              : null,
    );
  }

  Widget headerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            L10n.of(context).toAccess,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ItemPreviewCard(
          // showing the same item without the tap
          title: refDetails.title(),
          refType: typeFromRefDetails(refDetails),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            L10n.of(context).needToBeMemberOf,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

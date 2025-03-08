import 'package:acter/common/widgets/acter_icon_picker/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityReferencesItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReferencesItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.link,
      actionTitle: L10n.of(context).addedReferencesOn,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: getRefObjectWidget(context),
      originServerTs: activity.originServerTs(),
    );
  }

  Widget? getRefObjectWidget(BuildContext context) {
    final refDetails = activity.refDetails();
    final refType = refDetails?.typeStr();
    return switch (refType) {
      'pin' => RefObjectWidget(
        refDetails: refDetails,
        objectDefaultIcon: PhosphorIconsRegular.pushPin,
      ),
      'calendar-event' => RefObjectWidget(
        refDetails: refDetails,
        objectDefaultIcon: PhosphorIconsRegular.calendar,
      ),
      'task-list' => RefObjectWidget(
        refDetails: refDetails,
        objectDefaultIcon: PhosphorIconsRegular.listChecks,
      ),
      'task' => RefObjectWidget(
        refDetails: refDetails,
        objectDefaultIcon: PhosphorIconsRegular.check,
      ),
      _ => null,
    };
  }
}

class RefObjectWidget extends ConsumerWidget {
  final RefDetails? refDetails;
  final IconData? objectDefaultIcon;
  const RefObjectWidget({
    super.key,
    required this.refDetails,
    this.objectDefaultIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (refDetails == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ActerIconWidgetFromObjectIdAndType(
          objectId: refDetails?.targetIdStr(),
          objectType: refDetails?.typeStr(),
          fallbackWidget: Icon(
            objectDefaultIcon,
            size: 16,
            color: Theme.of(context).textTheme.labelMedium?.color,
          ),
        ),
        const SizedBox(width: 4),
        getRefTitleTextWidget(context),
      ],
    );
  }

  Widget getRefTitleTextWidget(BuildContext context) {
    final title = refDetails?.title();
    if (title == null) return const SizedBox.shrink();
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

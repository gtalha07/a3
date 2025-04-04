import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::add');

class SelectedActionButton extends ConsumerWidget {
  final RefDetails? refDetails;

  const SelectedActionButton({super.key, this.refDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (refDetails == null) return SizedBox();
    final refObjectType = refDetails?.typeStr();
    return switch (refObjectType) {
      'pin' => pinActionButton(context, ref, refDetails!),
      'calendar-event' => calendarActionButton(context, ref, refDetails!),
      'task-list' => taskListActionButton(context, ref, refDetails!),
      'link' => linkActionButton(context, ref, refDetails!),
      'space' => spaceActionButton(context, ref, refDetails!),
      'chat' => chatActionButton(context, ref, refDetails!),
      'super-invite' => superInviteCodeActionButton(context, ref, refDetails!),
      _ => const SizedBox(),
    };
  }

  Widget calendarActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final refObjectId = refDetails!.targetIdStr();
    if (refObjectId == null) return SizedBox();
    return ref
        .watch(calendarEventProvider(refObjectId))
        .when(
          data: (calendarEvent) {
            return SizedBox(
              width: 300,
              child: EventItem(
                eventId: calendarEvent.eventId().toString(),
                isShowRsvp: false,
                onTapEventItem: (event) async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectEventToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(width: 300, child: EventItemSkeleton()),
          error: (e, s) {
            _log.severe('Failed to load cal event', e, s);
            return Center(child: Text(L10n.of(context).failedToLoadEvent(e)));
          },
        );
  }

  Widget pinActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final refObjectId = refDetails!.targetIdStr();
    if (refObjectId == null) return SizedBox();
    return ref
        .watch(pinProvider(refObjectId))
        .when(
          data: (pin) {
            return SizedBox(
              width: 300,
              child: PinListItemWidget(
                pinId: pin.eventIdStr(),
                showPinIndication: true,
                onTaPinItem: (pinId) async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectPinToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(width: 300, child: EventItemSkeleton()),
          error: (e, s) {
            _log.severe('Failed to load cal event', e, s);
            return Center(child: Text(L10n.of(context).failedToLoadEvent(e)));
          },
        );
  }

  Widget taskListActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final refObjectId = refDetails!.targetIdStr();
    if (refObjectId == null) return SizedBox();
    return ref
        .watch(taskListProvider(refObjectId))
        .when(
          data: (taskList) {
            return SizedBox(
              width: 300,
              child: TaskListItemCard(
                showOnlyTaskList: true,
                canExpand: false,
                showTaskListIndication: true,
                taskListId: taskList.eventIdStr(),
                onTitleTap: () async {
                  final notifier = ref.read(newsStateProvider.notifier);
                  await notifier.selectTaskListToShare(context);
                },
              ),
            );
          },
          loading: () => const SizedBox(width: 300, child: TasksListSkeleton()),
          error: (e, s) {
            _log.severe('Failed to load task list', e, s);
            return Center(child: Text(L10n.of(context).errorLoadingTasks(e)));
          },
        );
  }

  Widget linkActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final uri = refDetail.uri();
    if (uri == null) return SizedBox.shrink();
    return SizedBox(
      width: 300,
      child: Card(
        child: ListTile(
          leading: const Icon(Atlas.link),
          onTap: () => openLink(ref: ref, target: uri, lang: L10n.of(context)),
          title: Text(
            refDetail.title() ?? L10n.of(context).unknown,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            uri,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }

  Widget spaceActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final roomId = refDetail.roomIdStr();
    if (roomId == null) return SizedBox();
    return SizedBox(
      width: 300,
      child: RoomCard(
        roomId: roomId,
        onTap: () async {
          final notifier = ref.read(newsStateProvider.notifier);
          await notifier.selectSpaceToShare(context);
        },
      ),
    );
  }

  Widget chatActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final roomId = refDetail.roomIdStr();
    if (roomId == null) return SizedBox();
    return SizedBox(
      width: 300,
      child: RoomCard(
        roomId: roomId,
        onTap: () async {
          final notifier = ref.read(newsStateProvider.notifier);
          await notifier.selectChatToShare(context);
        },
      ),
    );
  }

  Widget superInviteCodeActionButton(
    BuildContext context,
    WidgetRef ref,
    RefDetails refDetail,
  ) {
    final superInvite = refDetail.title();
    if (superInvite == null) return SizedBox.shrink();
    return SizedBox(
      width: 300,
      child: Card(
        child: ListTile(
          leading: const Icon(Atlas.ticket_coupon),
          onTap: () async {
            final notifier = ref.read(newsStateProvider.notifier);
            await notifier.selectInvitationCodeToShare(context);
          },
          title: Text(
            refDetail.title() ?? L10n.of(context).unknown,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            L10n.of(context).inviteCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

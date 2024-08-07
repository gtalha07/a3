import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabEntry {
  static const overview = Key('overview');
  static const pins = Key('pins');
  static const tasks = Key('tasks');
  static const events = Key('events');
  static const chatsKey = Key('chat');
  static const spacesKey = Key('spaces');
  static const membersKey = Key('members');
  static const actionsKey = Key('quickActionsKey');

  final Key key;
  final String label;

  const TabEntry({
    required this.key,
    required this.label,
  });
}

final tabsProvider =
    FutureProvider.family<List<TabEntry>, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);

  List<TabEntry> tabs = [];

  final spaceTopic = space.topic();
  if (spaceTopic != null) {
    tabs.add(
      const TabEntry(key: TabEntry.overview, label: 'Overview'),
    );
  }

  if ((await space.isActerSpace()) == true) {
    final appSettings = await space.appSettings();
    if (appSettings.pins().active()) {
      final pinsList = await ref.watch(pinListProvider(spaceId).future);
      if (pinsList.isNotEmpty) {
        tabs.add(
          const TabEntry(key: TabEntry.pins, label: 'Pins'),
        );
      }
    }

    if (appSettings.tasks().active()) {
      final taskList = await ref.watch(taskListProvider(spaceId).future);
      if (taskList.isNotEmpty) {
        tabs.add(
          const TabEntry(key: TabEntry.tasks, label: 'Tasks'),
        );
      }
    }

    if (appSettings.events().active()) {
      final eventList = await ref.watch(allEventListProvider(spaceId).future);
      if (eventList.isNotEmpty) {
        tabs.add(
          const TabEntry(key: TabEntry.events, label: 'Events'),
        );
      }
    }
  }

  final hasSpaces = await ref.watch(hasSubSpacesProvider(spaceId).future);
  if (hasSpaces) {
    tabs.add(
      const TabEntry(key: TabEntry.spacesKey, label: 'Spaces'),
    );
  }

  final hasChats = await ref.watch(hasSubChatsProvider(spaceId).future);
  if (hasChats) {
    tabs.add(
      const TabEntry(key: TabEntry.chatsKey, label: 'Chats'),
    );
  }

  tabs.add(
    const TabEntry(key: TabEntry.membersKey, label: 'Members'),
  );

  final membership = ref.watch(roomMembershipProvider(spaceId));
  bool canAddPin = membership.valueOrNull?.canString('CanPostPin') == true;
  bool canAddEvent = membership.valueOrNull?.canString('CanPostEvent') == true;
  bool canAddTask =
      membership.valueOrNull?.canString('CanPostTaskList') == true;
  bool canLinkSpaces =
      membership.valueOrNull?.canString('CanLinkSpaces') == true;

  //Show action menu only if you have at lease one permission
  if (canAddPin | canAddEvent | canAddTask | canLinkSpaces) {
    tabs.add(
      const TabEntry(key: TabEntry.actionsKey, label: '•••'),
    );
  }
  return tabs;
});

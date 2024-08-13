import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::widget::task_list_item');

class TaskListItemCard extends ConsumerWidget {
  final String taskListId;
  final bool showSpace;
  final bool showCompletedTask;
  final bool initiallyExpanded;

  const TaskListItemCard({
    super.key,
    required this.taskListId,
    this.showSpace = false,
    this.showCompletedTask = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(taskListItemProvider(taskListId)).when(
          data: (taskList) => Card(
            key: Key('task-list-card-$taskListId'),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              iconColor: Theme.of(context).colorScheme.onSurface,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: title(context, taskList),
              subtitle: subtitle(ref, taskList),
              children: [
                TaskItemsListWidget(
                  taskList: taskList,
                  showCompletedTask: showCompletedTask,
                ),
              ],
            ),
          ),
          error: (error, stack) {
            _log.severe('failed to load tasklist', error, stack);
            return Card(
              child: Text('Loading of tasklist failed: $error'),
            );
          },
          loading: () => const Card(
            child: Text('loading'),
          ),
        );
  }

  Widget title(BuildContext context, TaskList taskList) {
    return InkWell(
      onTap: () {
        context.pushNamed(
          Routes.taskListDetails.name,
          pathParameters: {'taskListId': taskListId},
        );
      },
      child: Text(
        key: Key('task-list-title-$taskListId'),
        taskList.name(),
      ),
    );
  }

  Widget? subtitle(WidgetRef ref, TaskList taskList) {
    final spaceProfile =
        ref.watch(roomAvatarInfoProvider(taskList.spaceIdStr()));

    return showSpace ? Text(spaceProfile.displayName ?? '') : null;
  }
}

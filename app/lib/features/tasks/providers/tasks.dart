import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/notifiers.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, TasksOverview, TaskList>(() {
  return TasksNotifier();
});

class TaskQuery {
  final String taskListId;
  final String taskId;
  const TaskQuery(this.taskListId, this.taskId);
}

final taskProvider =
    FutureProvider.autoDispose.family<Task, TaskQuery>((ref, query) async {
  final taskList = await ref.watch(taskListProvider(query.taskListId).future);
  return await taskList.task(query.taskId);
});

final taskCommentsProvider =
    FutureProvider.autoDispose.family<CommentsManager, Task>((ref, t) async {
  return await t.comments();
});

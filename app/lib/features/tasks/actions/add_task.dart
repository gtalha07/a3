import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/tasks/actions/select_tasklist.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_task');

Future<void> migrateTaskDescription(Task task) async {
  final description = task.description();
  if (description == null) return;
  
  // Only migrate if the description doesn't have HTML format
  if (description.formattedBody() == null) {
    try {
      final updater = task.updateBuilder();
      final plainText = description.body();
      updater.descriptionHtml(plainText, plainText);
      await updater.send();
    } catch (e, s) {
      _log.severe('Failed to migrate task description', e, s);
    }
  }
}

Future<(String, String)?> addTask({
  required BuildContext context,
  required WidgetRef ref,
  TaskList? taskList,
  required String title,
  String? description,
  DateTime? dueDate,
}) async {
  final lang = L10n.of(context);

  taskList ??= await selectTaskList(context: context, ref: ref);
  if (taskList == null) {
    EasyLoading.showError(
      lang.selectTaskList,
      duration: const Duration(seconds: 2),
    );
    return null;
  }

  EasyLoading.show(status: lang.addingTask);
  final taskDraft = taskList.taskBuilder();
  taskDraft.title(title);
  if (description != null && description.isNotEmpty == true) {
    taskDraft.descriptionHtml(description, description);
  }
  if (dueDate != null) {
    taskDraft.dueDate(dueDate.year, dueDate.month, dueDate.day);
  }
  try {
    final eventId = await taskDraft.send();
    final tlId = taskList.eventIdStr();

    await autosubscribe(ref: ref, objectId: eventId.toString(), lang: lang);
    await autosubscribe(ref: ref, objectId: tlId.toString(), lang: lang);
    EasyLoading.dismiss();
    return (tlId, eventId.toString());
  } catch (e, s) {
    _log.severe('Failed to create task', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.showError(
        lang.creatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
    return null;
  }
}

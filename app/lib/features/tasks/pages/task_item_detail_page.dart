import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_item_detail_page_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::tasks::task_item_details_page');

class TaskItemDetailPage extends ConsumerWidget {
  static const taskListTitleKey = Key('task-list-title');
  final String taskListId;
  final String taskId;

  const TaskItemDetailPage({
    required this.taskListId,
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task =
        ref.watch(taskProvider((taskListId: taskListId, taskId: taskId)));
    return Scaffold(
      appBar: _buildAppBar(context, ref, task),
      body: _buildBody(context, ref, task),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> task,
  ) {
    return task.when(
      data: (data) => AppBar(
        title: SelectionArea(
          child: GestureDetector(
            onTap: () => showEditTaskItemNameBottomSheet(
              context: context,
              ref: ref,
              task: data,
              titleValue: data.title(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.list,
                      color: Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      L10n.of(context).taskList,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    showEditTitleBottomSheet(
                      context: context,
                      bottomSheetTitle: L10n.of(context).editName,
                      titleValue: data.title(),
                      onSave: (newName) =>
                          saveTitle(context, ref, data, newName),
                    );
                  },
                  child: Text(
                    L10n.of(context).editTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showEditDescriptionSheet(context, ref, data),
                  child: Text(
                    L10n.of(context).editDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () =>
                      showRedactDialog(context: context, ref: ref, task: data),
                  child: Text(
                    L10n.of(context).delete,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showReportDialog(context: context, task: data),
                  child: Text(
                    L10n.of(context).report,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      error: (e, s) => AppBar(title: Text(L10n.of(context).failedToLoad(e))),
      loading: () => AppBar(title: Text(L10n.of(context).loading)),
    );
  }

  // Redact Task Item Dialog
  void showRedactDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Task task,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => RedactContentWidget(
        title: L10n.of(context).deleteTaskItem,
        onSuccess: () {
          ref.invalidate(tasksProvider);
          ref.invalidate(taskListProvider);
          Navigator.of(context, rootNavigator: true).pop();
        },
        eventId: task.eventIdStr(),
        senderId: task.authorStr(),
        roomId: task.roomIdStr(),
        isSpace: true,
      ),
    );
  }

  // Report Task Item Dialog
  void showReportDialog({
    required BuildContext context,
    required Task task,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => ReportContentWidget(
        title: L10n.of(context).reportTaskItem,
        description: L10n.of(context).reportThisContent,
        eventId: task.eventIdStr(),
        senderId: task.authorStr(),
        roomId: task.roomIdStr(),
        isSpace: true,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> task,
  ) {
    return task.when(
      data: (data) => taskData(context, data, ref),
      error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
      loading: () => const TaskItemDetailPageSkeleton(),
    );
  }

  Widget taskData(BuildContext context, Task task, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _widgetDescription(context, task, ref),
            const SizedBox(height: 10),
            _widgetTaskDate(context, task),
            _widgetTaskAssignment(context, task, ref),
            const SizedBox(height: 20),
            AttachmentSectionWidget(manager: task.attachments()),
            const SizedBox(height: 20),
            CommentsSection(manager: task.comments()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _widgetDescription(BuildContext context, Task task, WidgetRef ref) {
    final description = task.description();
    if (description == null) return const SizedBox.shrink();
    final formattedBody = description.formattedBody();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectionArea(
          child: GestureDetector(
            onTap: () {
              showEditDescriptionSheet(context, ref, task);
            },
            child: formattedBody != null
                ? RenderHtml(
                    text: formattedBody,
                    defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                  )
                : Text(
                    description.body(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void showEditDescriptionSheet(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: task.description()?.formattedBody(),
      descriptionMarkdownValue: task.description()?.body(),
      onSave: (htmlBodyDescription, plainDescription) {
        _saveDescription(
          context,
          ref,
          task,
          htmlBodyDescription,
          plainDescription,
        );
      },
    );
  }

  Future<void> _saveDescription(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String htmlBodyDescription,
    String plainDescription,
  ) async {
    EasyLoading.show(status: L10n.of(context).updatingDescription);
    try {
      final updater = task.updateBuilder();
      updater.descriptionHtml(plainDescription, htmlBodyDescription);
      await updater.send();
      EasyLoading.dismiss();
      if (context.mounted) context.pop();
    } catch (e, st) {
      _log.severe('Failed to update event description', e, st);
      EasyLoading.dismiss();
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).errorUpdatingDescription(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskDate(BuildContext context, Task task) {
    return ListTile(
      dense: true,
      leading: const Icon(Atlas.calendar_date_thin),
      title: Text(
        L10n.of(context).dueDate,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          task.dueDate() != null
              ? taskDueDateFormat(DateTime.parse(task.dueDate()!))
              : L10n.of(context).noDueDate,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      onTap: () => duePickerAction(context, task),
    );
  }

  Future<void> duePickerAction(BuildContext context, Task task) async {
    final newDue = await showDuePicker(
      context: context,
      initialDate: task.dueDate() != null
          ? DateTime.parse(task.dueDate()!)
          : DateTime.now(),
    );
    if (!context.mounted) return;
    if (newDue == null) return;
    EasyLoading.show(status: L10n.of(context).updatingDue);
    try {
      final updater = task.updateBuilder();
      updater.dueDate(newDue.due.year, newDue.due.month, newDue.due.day);
      if (newDue.includeTime) {
        final seconds = newDue.due.hour * 60 * 60 +
            newDue.due.minute * 60 +
            newDue.due.second;
        // adapt the timezone value
        updater.utcDueTimeOfDay(seconds + newDue.due.timeZoneOffset.inSeconds);
      } else if (task.utcDueTimeOfDay() != null) {
        // we have one, we need to reset it
        updater.unsetUtcDueTimeOfDay();
      }
      await updater.send();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).dueSuccess);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updatingDueFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskAssignment(BuildContext context, Task task, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: const Icon(Atlas.business_man_thin),
      title: Row(
        children: [
          Text(
            L10n.of(context).assignment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () => task.isAssignedToMe()
                ? onUnAssign(context, task)
                : onAssign(context, task),
            child: Text(
              task.isAssignedToMe()
                  ? L10n.of(context).removeMyself
                  : L10n.of(context).assignMyself,
            ),
          ),
        ],
      ),
      subtitle: task.isAssignedToMe()
          ? assigneeName(context, task, ref)
          : Text(
              L10n.of(context).noAssignment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
    );
  }

  Widget assigneeName(
    BuildContext context,
    Task task,
    WidgetRef ref,
  ) {
    final assignees = task.assigneesStr().map((s) => s.toDartString()).toList();

    return Wrap(
      direction: Axis.horizontal,
      children: assignees.map((i) {
        final memberData = ref.watch(
          roomMemberProvider(
            (roomId: task.roomIdStr(), userId: i),
          ),
        );
        return memberData.when(
          data: (data) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              labelPadding: EdgeInsets.zero,
              label: Text(
                data.profile.displayName ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          error: (error, stackTrace) => Text(
            L10n.of(context).errorLoading(error),
          ),
          loading: () => Skeletonizer(
            child: Text(L10n.of(context).loading),
          ),
        );
      }).toList(),
    );
  }

  Future<void> onAssign(BuildContext context, Task task) async {
    EasyLoading.show(status: L10n.of(context).assigningSelf);
    try {
      await task.assignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignedYourself);
    } catch (e, st) {
      _log.severe('Failed to assign self', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToAssignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onUnAssign(
    BuildContext context,
    Task task,
  ) async {
    EasyLoading.show(status: L10n.of(context).unassigningSelf);
    try {
      await task.unassignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignmentWithdrawn);
    } catch (e, st) {
      _log.severe('Failed to unassign self', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToUnassignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void showEditTaskItemNameBottomSheet({
    required BuildContext context,
    required String titleValue,
    required Task task,
    required WidgetRef ref,
  }) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: titleValue,
      onSave: (newName) => saveTitle(context, ref, task, newName),
    );
  }

  void saveTitle(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String newName,
  ) async {
    EasyLoading.show(status: L10n.of(context).updatingTask);
    final updater = task.updateBuilder();
    updater.title(newName);
    try {
      await updater.send();
      ref.invalidate(spaceTasksListsProvider);
      EasyLoading.dismiss();
      if (!context.mounted) return;
      context.pop();
    } catch (e) {
      EasyLoading.dismiss();
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).updatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/action_button_widget.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickActionButtons extends ConsumerWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSpaces = ref.watch(hasSpacesProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            children: hasSpaces
                ? quickActionWhenHasSpaces(context, ref)
                : quickActionWhenNoSpaces(context, ref),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> quickActionWhenHasSpaces(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final canAddPin =
        ref.watch(hasSpaceWithPermissionProvider('CanPostPin')).valueOrNull ??
            false;
    final canAddEvent =
        ref.watch(hasSpaceWithPermissionProvider('CanPostEvent')).valueOrNull ??
            false;
    final canAddTask = ref
            .watch(hasSpaceWithPermissionProvider('CanPostTaskList'))
            .valueOrNull ??
        false;
    final canAddBoost =
        ref.watch(hasSpaceWithPermissionProvider('CanPostNews')).valueOrNull ??
            false;
    return [
      if (canAddPin)
        ActionButtonWidget(
          iconData: Atlas.pin,
          color: pinFeatureColor,
          title: lang.addPin,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.createPin.name);
          },
        ),
      if (canAddTask)
        ActionButtonWidget(
          iconData: Atlas.list,
          title: lang.addTaskList,
          color: taskFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            showCreateUpdateTaskListBottomSheet(context);
          },
        ),
      if (canAddEvent)
        ActionButtonWidget(
          iconData: Atlas.calendar_dots,
          title: lang.addEvent,
          color: eventFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.createEvent.name);
          },
        ),
      if (canAddBoost)
        ActionButtonWidget(
          iconData: Atlas.megaphone_thin,
          title: lang.addBoost,
          color: boastFeatureColor,
          padding: const EdgeInsets.symmetric(vertical: 6),
          onPressed: () {
            ref.read(quickActionVisibilityProvider.notifier).state = false;
            context.pushNamed(Routes.actionAddUpdate.name);
          },
        ),
    ];
  }

  List<Widget> quickActionWhenNoSpaces(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return [
      ActionButtonWidget(
        iconData: Atlas.users,
        title: lang.createSpace,
        color: Colors.purpleAccent.withAlpha(70),
        padding: const EdgeInsets.symmetric(vertical: 6),
        onPressed: () {
          ref.read(quickActionVisibilityProvider.notifier).state = false;
          context.pushNamed(Routes.createSpace.name);
        },
      ),
      ActionButtonWidget(
        iconData: Atlas.chats,
        title: lang.createChat,
        color: Colors.green.withAlpha(70),
        padding: const EdgeInsets.symmetric(vertical: 6),
        onPressed: () {
          ref.read(quickActionVisibilityProvider.notifier).state = false;
          context.pushNamed(Routes.createChat.name);
        },
      ),
    ];
  }
}

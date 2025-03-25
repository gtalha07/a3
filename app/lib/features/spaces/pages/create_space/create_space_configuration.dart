import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/room/join_rule/room_join_rule_item.dart';
import 'package:acter/features/room/join_rule/room_join_rule_selector.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/features/spaces/pages/create_space/create_space_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateSpaceConfiguration extends ConsumerStatefulWidget {
  final String? initialParentsSpaceId;

  const CreateSpaceConfiguration({super.key, this.initialParentsSpaceId});

  @override
  ConsumerState<CreateSpaceConfiguration> createState() =>
      _CreateSpaceConfigurationState();
}

class _CreateSpaceConfigurationState
    extends ConsumerState<CreateSpaceConfiguration> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed:
              () => ref
                  .read(showSpaceCreationConfigurationProvider.notifier)
                  .update((state) => false),
          icon: const Icon(Atlas.arrow_left),
        ),
        title: const Text('Configure Space'),
        centerTitle: true,
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParentSpace(),
          const SizedBox(height: 20),
          _buildVisibility(),
          const SizedBox(height: 20),
          _buildDefaultChatField(),
        ],
      ),
    );
  }

  Widget _buildDefaultChatField() {
    return InkWell(
      onTap:
          () => ref
              .read(createDefaultChatProvider.notifier)
              .update((state) => !state),
      child: Row(
        children: [
          Switch(
            value: ref.watch(createDefaultChatProvider),
            onChanged: (newValue) {
              ref
                  .read(createDefaultChatProvider.notifier)
                  .update((state) => newValue);
            },
          ),
          Text(L10n.of(context).createDefaultChat),
        ],
      ),
    );
  }

  Widget _buildParentSpace() {
    final lang = L10n.of(context);
    return SelectSpaceFormField(
      canCheck: (m) => m?.canString('CanLinkSpaces') == true,
      mandatory: false,
      title: lang.parentSpace,
      selectTitle: lang.selectParentSpace,
      emptyText: lang.optionalParentSpace,
    );
  }

  Widget _buildVisibility() {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.visibilityTitle, style: textTheme.bodyMedium),
        Text(lang.visibilitySubtitle, style: textTheme.bodySmall),
        const SizedBox(height: 10),
        InkWell(
          key: CreateSpacePage.permissionsKey,
          onTap: () async {
            final spaceVisibility = ref.read(selectedJoinRuleProvider);
            final selectedSpace = ref.read(selectedSpaceIdProvider);
            final selected = await selectJoinRuleDrawer(
              context: context,
              selectedJoinRuleEnum: spaceVisibility,
              isLimitedJoinRuleShow: selectedSpace != null,
            );
            if (selected != null) {
              final notifier = ref.read(selectedJoinRuleProvider.notifier);
              notifier.update((state) => selected);
            }
          },
          child: selectedJoinRule(),
        ),
      ],
    );
  }

  Widget selectedJoinRule() {
    final lang = L10n.of(context);
    return switch (ref.watch(selectedJoinRuleProvider)) {
      RoomJoinRule.Public => RoomJoinRuleItem(
        iconData: Icons.language,
        title: lang.public,
        subtitle: lang.publicVisibilitySubtitle,
        isShowRadio: false,
      ),
      RoomJoinRule.Invite => RoomJoinRuleItem(
        iconData: Icons.lock,
        title: lang.private,
        subtitle: lang.privateVisibilitySubtitle,
        isShowRadio: false,
      ),
      RoomJoinRule.Restricted => RoomJoinRuleItem(
        iconData: Atlas.users,
        title: lang.limited,
        subtitle: lang.limitedVisibilitySubtitle,
        isShowRadio: false,
      ),
      _ => RoomJoinRuleItem(
        iconData: Icons.lock,
        title: lang.private,
        subtitle: lang.privateVisibilitySubtitle,
        isShowRadio: false,
      ),
    };
  }
}

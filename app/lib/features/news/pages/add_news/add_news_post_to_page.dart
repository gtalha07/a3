import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/actions/submit_story.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PostTypeSelection { story, boost, none }

class AddNewsPostToPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const AddNewsPostToPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<AddNewsPostToPage> createState() => _AddNewsPostToPageState();
}

class _AddNewsPostToPageState extends ConsumerState<AddNewsPostToPage> {
  ValueNotifier<PostTypeSelection> selectedPostType =
      ValueNotifier(PostTypeSelection.none);
  ValueNotifier<bool> canPostBoost = ValueNotifier(false);
  ValueNotifier<bool> canPostStories = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    //Initialize variables based on the selected space
    final selectedSpaceId = ref.read(newsStateProvider).newsPostSpaceId;
    if (selectedSpaceId != null) {
      final membership =
          ref.watch(roomMembershipProvider(selectedSpaceId)).valueOrNull;
      canPostBoost.value = membership?.canString('CanPostNews') == true;
      canPostStories.value = membership?.canString('CanPostStories') == true;
      selectedPostType.value = PostTypeSelection.none;
    }

    //Start build UI
    return Scaffold(
      appBar: appBarUI(),
      body: postToBodyUI(selectedSpaceId),
    );
  }

  AppBar appBarUI() {
    final lang = L10n.of(context);
    return AppBar(title: Text(lang.postTo));
  }

  Widget postToBodyUI(String? selectedSpaceId) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        spaceSelector(),
        SectionHeader(title: lang.select),
        ValueListenableBuilder<bool>(
          valueListenable: canPostStories,
          builder: (context, canPostStories, child) {
            return postOptionItemUI(
              isEnable: canPostStories,
              title: lang.story,
              description: lang.storyInfo,
              iconData: Icons.amp_stories,
              postTypeSelection: PostTypeSelection.story,
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: canPostBoost,
          builder: (context, canPostBoost, child) {
            return postOptionItemUI(
              isEnable: canPostBoost,
              title: lang.boost,
              description: lang.boostInfo,
              iconData: Icons.rocket_launch_sharp,
              postTypeSelection: PostTypeSelection.boost,
            );
          },
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.all(18),
          child: ActerPrimaryActionButton(
            onPressed: () {
              if (selectedSpaceId == null || selectedSpaceId.isEmpty) {
                EasyLoading.showToast(lang.pleaseSelectSpace);
              } else if (canPostBoost.value == false &&
                  canPostStories.value == false) {
                EasyLoading.showToast(lang.notHaveBoostStoryPermission);
              } else if (selectedPostType.value == PostTypeSelection.none) {
                EasyLoading.showToast(lang.pleaseSelectePostType);
              } else if (selectedPostType.value == PostTypeSelection.story) {
                sendStory(context, ref);
              } else if (selectedPostType.value == PostTypeSelection.boost) {
                sendNews(context, ref);
              }
            },
            child: Text(lang.post.toUpperCase()),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget spaceSelector() {
    final newsPostSpaceId = ref.watch(newsStateProvider).newsPostSpaceId;

    final spaceSelectorWidget = (newsPostSpaceId != null)
        ? InkWell(
            key: UpdateKeys.selectSpace,
            onTap: () async {
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.changeNewsPostSpaceId(context);
            },
            child: Row(
              children: [
                RoomAvatarBuilder(roomId: newsPostSpaceId, avatarSize: 42),
                SizedBox(width: 16),
                SpaceNameWidget(
                  spaceId: newsPostSpaceId,
                  isShowBrackets: false,
                ),
              ],
            ),
          )
        : OutlinedButton(
            key: UpdateKeys.selectSpace,
            onPressed: () async {
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.changeNewsPostSpaceId(context);
            },
            child: Text(L10n.of(context).selectSpace),
          );

    return Padding(
      padding: const EdgeInsets.all(18),
      child: spaceSelectorWidget,
    );
  }

  Widget postOptionItemUI({
    required bool isEnable,
    required String title,
    required String description,
    required IconData iconData,
    required PostTypeSelection postTypeSelection,
  }) {
    final color = !isEnable ? Theme.of(context).disabledColor : null;
    return InkWell(
      onTap: isEnable ? () => selectedPostType.value = postTypeSelection : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(iconData, color: color),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color)),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<PostTypeSelection>(
              valueListenable: selectedPostType,
              builder: (context, postType, child) {
                return Radio(
                  value: postTypeSelection,
                  groupValue: postType,
                  onChanged: isEnable
                      ? (value) => selectedPostType.value = postType
                      : null,
                  toggleable: isEnable,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

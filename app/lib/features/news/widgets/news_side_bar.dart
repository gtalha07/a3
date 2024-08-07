import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_bottom_sheet.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::news::sidebar');

class NewsSideBar extends ConsumerWidget {
  final ffi.NewsEntry news;
  final int index;

  const NewsSideBar({
    super.key,
    required this.news,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = news.roomId().toString();
    final userId = ref.watch(myUserIdStrProvider);
    final isLikedByMe = ref.watch(likedByMeProvider(news));
    final likesCount = ref.watch(totalLikesForNewsProvider(news));
    final space = ref.watch(briefSpaceItemProvider(roomId));
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        const Spacer(),
        LikeButton(
          isLiked: isLikedByMe.valueOrNull ?? false,
          likeCount: likesCount.valueOrNull ?? 0,
          style: style,
          color: Theme.of(context).colorScheme.textColor,
          index: index,
          onTap: () async {
            final manager = await ref.read(newsReactionsProvider(news).future);
            final status = manager.likedByMe();
            _log.info('my like status: $status');
            if (!status) {
              await manager.sendLike();
            } else {
              await manager.redactLike(null, null);
            }
          },
        ),
        const SizedBox(height: 10),
        space.maybeWhen(
          data: (space) => InkWell(
            key: NewsUpdateKeys.newsSidebarActionBottomSheet,
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) => DefaultBottomSheet(
                content: ActionBox(
                  news: news,
                  userId: userId,
                  roomId: roomId,
                ),
              ),
            ),
            child: _SideBarItem(
              icon: const Icon(Atlas.dots_horizontal_thin),
              label: '',
              style: style,
            ),
          ),
          orElse: () => _SideBarItem(
            icon: const Icon(Atlas.dots_horizontal_thin),
            label: '',
            style: style,
          ),
        ),
        const SizedBox(height: 10),
        space.when(
          data: (space) => ActerAvatar(
            options: AvatarOptions(
              AvatarInfo(
                uniqueId: roomId,
                displayName: space.avatarInfo.displayName,
                avatar: space.avatarInfo.avatar,
                onAvatarTap: () => goToSpace(context, roomId),
              ),
              size: 42,
            ),
          ),
          error: (e, st) {
            _log.severe('Error loading space', e, st);
            return ActerAvatar(
              options: AvatarOptions(
                AvatarInfo(
                  uniqueId: roomId,
                  displayName: roomId,
                ),
                size: 42,
              ),
            );
          },
          loading: () => Skeletonizer(
            child: ActerAvatar(
              options: AvatarOptions(
                AvatarInfo(uniqueId: roomId),
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

class _SideBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final TextStyle style;

  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
        const SizedBox(height: 5),
        Text(label, style: style),
      ],
    );
  }
}

class ActionBox extends ConsumerWidget {
  final String userId;
  final ffi.NewsEntry news;
  final String roomId;

  const ActionBox({
    super.key,
    required this.news,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderId = news.sender().toString();
    final canRedact = ref.watch(canRedactProvider(news));
    final isAuthor = senderId == userId;
    List<Widget> actions = [
      Text(L10n.of(context).actions),
      const Divider(),
    ];

    if (canRedact.valueOrNull == true) {
      actions.add(
        TextButton.icon(
          key: NewsUpdateKeys.newsSidebarActionRemoveBtn,
          onPressed: () => openRedactContentDialog(
            context,
            title: L10n.of(context).removeThisPost,
            eventId: news.eventId().toString(),
            onSuccess: () async {
              if (!await Navigator.maybePop(context)) {
                if (context.mounted) {
                  // fallback to go to home
                  Navigator.pushReplacementNamed(context, Routes.main.name);
                }
              }
            },
            roomId: roomId,
            isSpace: true,
            removeBtnKey: NewsUpdateKeys.removeButton,
          ),
          icon: const Icon(Atlas.trash_thin),
          label: Text(L10n.of(context).remove),
        ),
      );
    } else if (!isAuthor) {
      actions.add(
        TextButton.icon(
          key: NewsUpdateKeys.newsSidebarActionReportBtn,
          onPressed: () => openReportContentDialog(
            context,
            title: L10n.of(context).reportThisPost,
            eventId: news.eventId().toString(),
            description: L10n.of(context).reportPostContent,
            senderId: senderId,
            roomId: roomId,
            isSpace: true,
          ),
          icon: const Icon(Atlas.exclamation_chat_thin),
          label: Text(L10n.of(context).reportThis),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }
}

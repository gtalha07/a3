import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/chat/convo_with_avatar_card.dart';
import 'package:acter/common/widgets/room/room_hierarchy_join_button.dart';
import 'package:acter/common/widgets/room/room_hierarchy_options_menu.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConvoHierarchyCard extends ConsumerWidget {
  /// The room info to display
  final SpaceHierarchyRoomInfo roomInfo;

  /// The parent roomId this is rendered for
  final String parentId;

  /// the Size of the Avatar to render
  final double avatarSize;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// The text style for ListTile's [title].
  ///
  /// If this property is null, then [ListTileThemeData.titleTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.bodyLarge]
  /// will be used. Otherwise, If ListTile style is [ListTileStyle.list],
  /// [TextTheme.titleMedium] will be used and if ListTile style is [ListTileStyle.drawer],
  /// [TextTheme.bodyLarge] will be used.
  final TextStyle? titleTextStyle;

  /// The text style for ListTile's [subtitle].
  ///
  /// If this property is null, then [ListTileThemeData.subtitleTextStyle] is used.
  /// If that is also null, [TextTheme.bodyMedium] will be used.
  final TextStyle? subtitleTextStyle;

  /// The text style for ListTile's [leading] and [trailing].
  ///
  /// If this property is null, then [ListTileThemeData.leadingAndTrailingTextStyle] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, [TextTheme.labelSmall]
  /// will be used, otherwise [TextTheme.bodyMedium] will be used.
  final TextStyle? leadingAndTrailingTextStyle;

  /// The tile's internal padding.
  ///
  /// Insets a [ListTile]'s contents: its [leading], [title], [subtitle],
  /// and [trailing] widgets.
  ///
  /// If null, `EdgeInsets.symmetric(horizontal: 16.0)` is used.
  final EdgeInsetsGeometry? contentPadding;

  /// The shape of the card's [Material].
  ///
  /// Defines the card's [Material.shape].
  ///
  /// If this property is null then [CardTheme.shape] of [ThemeData.cardTheme]
  /// is used. If that's null then the shape will be a [RoundedRectangleBorder]
  /// with a circular corner radius of 4.0.
  final ShapeBorder? shape;

  /// Whether or not to render a border around that element.
  ///
  /// Overwritten if you provider a `shape`. Otherwise, if set to true renders
  /// the default border.
  final bool withBorder;

  /// Custom trailing widget.
  final Widget? trailing;

  /// Whether to show the suggested icon if this is a suggested chat
  final bool showIconIfSuggested;

  const ConvoHierarchyCard({
    super.key,
    required this.roomInfo,
    required this.parentId,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.avatarSize = 48,
    this.contentPadding = const EdgeInsets.all(15),
    this.shape,
    this.withBorder = true,
    this.showIconIfSuggested = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = roomInfo.roomIdStr();
    final avatarInfo = ref.watch(roomHierarchyAvatarInfoProvider(roomInfo));
    final topic = roomInfo.topic();
    final subtitle = topic?.isNotEmpty == true ? Text(topic!) : null;
    bool showSuggested = showIconIfSuggested && roomInfo.suggested();

    return ConvoWithAvatarInfoCard(
      avatar: ActerAvatar(
        options: AvatarOptions(
          avatarInfo,
          size: avatarSize,
          badgesSize: avatarSize / 2,
        ),
      ),
      roomId: roomId,
      avatarInfo: avatarInfo,
      showSuggestedMark: showSuggested,
      subtitle: subtitle,
      trailing: trailing ??
          Wrap(
            children: [
              RoomHierarchyJoinButton(
                joinRule: roomInfo.joinRuleStr().toLowerCase(),
                roomId: roomId,
                roomName: roomInfo.name() ?? roomInfo.roomIdStr(),
                viaServerName: roomInfo.viaServerName(),
                forward: (roomId) {
                  goToChat(context, roomId);
                  // make sure the UI refreshes when the user comes back here
                  ref.invalidate(spaceRelationsProvider(parentId));
                  ref.invalidate(spaceRemoteRelationsProvider(parentId));
                },
              ),
              RoomHierarchyOptionsMenu(
                isSuggested: roomInfo.suggested(),
                childId: roomId,
                parentId: parentId,
              ),
            ],
          ),
      onTap: onTap,
      onFocusChange: onFocusChange,
      onLongPress: onLongPress,
    );
  }
}

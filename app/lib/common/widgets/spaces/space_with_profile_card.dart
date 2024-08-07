import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceWithAvatarInfoCard extends StatelessWidget {
  final String roomId;
  final AvatarInfo avatarInfo;
  final List<AvatarInfo>? parents;
  final Widget? subtitle;
  final Widget? trailing;
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

  /// If null, `EdgeInsets.symmetric(horizontal: 16.0)` is used.
  final EdgeInsetsGeometry? margin;

  /// The shape of the card's [Material].
  ///
  /// Defines the card's [Material.shape].
  ///
  /// If this property is null then [CardTheme.shape] of [ThemeData.cardTheme]
  /// is used. If that's null then the shape will be a [RoundedRectangleBorder]
  /// with a circular corner radius of 4.0.
  final ShapeBorder? shape;

  /// Whether or not to render the parent(s) Icon
  ///
  final bool showParents;

  /// Whether or not to render the suggested icon
  ///
  final bool showSuggestedMark;

  const SpaceWithAvatarInfoCard({
    super.key,
    required this.roomId,
    required this.avatarInfo,
    this.parents,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.leadingAndTrailingTextStyle,
    this.shape,
    this.showParents = true,
    this.margin,
    this.showSuggestedMark = false,
    required this.avatarSize,
    required this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = avatarInfo.displayName;
    final title = displayName?.isNotEmpty == true ? displayName! : roomId;

    final avatar = ActerAvatar(
      options: AvatarOptions(
        AvatarInfo(
          uniqueId: roomId,
          displayName: title,
          avatar: avatarInfo.avatar,
        ),
        parentBadges: showParents ? parents : [],
        size: avatarSize,
        badgesSize: avatarSize / 2,
      ),
    );

    return Card(
      margin: margin,
      child: ListTile(
        contentPadding: contentPadding,
        onTap: onTap ?? () => context.push('/$roomId'),
        onFocusChange: onFocusChange,
        onLongPress: onLongPress,
        titleTextStyle: titleTextStyle,
        subtitleTextStyle: subtitleTextStyle,
        leadingAndTrailingTextStyle: leadingAndTrailingTextStyle,
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: buildSubtitle(context),
        leading: avatar,
        trailing: trailing,
      ),
    );
  }

  Widget? buildSubtitle(BuildContext context) {
    if (!showSuggestedMark) {
      return subtitle;
    }

    if (subtitle != null) {
      return Row(
        children: [
          Text(
            L10n.of(context).suggested,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 2),
          Expanded(child: subtitle!),
        ],
      );
    }

    return Text(
      L10n.of(context).suggested,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}

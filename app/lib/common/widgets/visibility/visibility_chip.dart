import 'package:acter/common/actions/show_limited_space_list.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::visibility::chip');

class VisibilityChip extends ConsumerWidget {
  final String roomId;

  const VisibilityChip({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityLoader = ref.watch(roomVisibilityProvider(roomId));
    return visibilityLoader.when(
      data: (visibility) {
        return GestureDetector(
          onTap: () {
            if (visibility != RoomVisibility.SpaceVisible) return;
            showLimitedSpaceList(context, ref, roomId);
          },
          child: renderSpaceChip(context, visibility),
        );
      },
      error: (e, s) {
        _log.severe('Failed to load room visibility', e, s);
        return Chip(
          label: Text(L10n.of(context).loadingFailed(e)),
        );
      },
      loading: () => renderLoading(),
    );
  }

  Widget renderLoading() {
    return Skeletonizer(
      child: SizedBox(
        width: 100,
        child: Chip(
          avatar: const Icon(Icons.language),
          label: Text(roomId),
        ),
      ),
    );
  }

  Widget renderSpaceChip(BuildContext context, RoomVisibility? visibility) {
    IconData icon = Icons.lock;
    String label = L10n.of(context).private;
    switch (visibility) {
      case RoomVisibility.Public:
        icon = Icons.language;
        label = L10n.of(context).public;
        break;
      case RoomVisibility.SpaceVisible:
        icon = Atlas.users;
        label = L10n.of(context).limited;
      default:
        break;
    }
    return Chip(
      visualDensity: VisualDensity.compact,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      avatar: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastMessageTimeWidget extends ConsumerWidget {
  final String roomId;
  const LastMessageTimeWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeColor = theme.colorScheme.surfaceTint;
    final lastMessageTimestamp = _getLastMessageTimestamp(ref);

    if (lastMessageTimestamp == null) return const SizedBox.shrink();

    return Text(
      jiffyTime(context, lastMessageTimestamp),
      style: theme.textTheme.bodySmall?.copyWith(
        color: timeColor,
        fontSize: 12,
      ),
    );
  }

  int? _getLastMessageTimestamp(WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    final TimelineEventItem? eventItem = latestMessage?.eventItem();
    final lastMessageTimestamp = eventItem?.originServerTs();
    return lastMessageTimestamp;
  }
}

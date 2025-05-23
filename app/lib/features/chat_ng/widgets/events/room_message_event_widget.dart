import 'package:acter/features/chat_ng/widgets/events/media_meessage_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/general_message_event_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoomMessageEventWidget extends StatelessWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const RoomMessageEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return switch (eventItem.msgType()) {
      'm.text' => GeneralMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
      ),
      'm.image' => MediaMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.image,
        icon: PhosphorIcons.image(),
      ),
      'm.video' => MediaMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.video,
        icon: PhosphorIcons.video(),
      ),
      'm.audio' => MediaMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.audio,
        icon: PhosphorIcons.musicNote(),
      ),
      'm.file' => MediaMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.file,
        icon: PhosphorIcons.file(),
      ),
      'm.location' => MediaMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.location,
        icon: PhosphorIcons.mapPin(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_ffi_list_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item_diff.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/mocks/room/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_stream.dart';
import 'package:acter/features/chat_ui_showcase/mocks/user/mock_user.dart';

class MockChatItem {
  final String roomId;
  final MockRoom mockRoom;
  final MockConvo mockConvo;
  final List<MockUser>? typingUsers;

  MockChatItem({
    required this.roomId,
    required this.mockRoom,
    required this.mockConvo,
    required this.typingUsers,
  });
}

MockChatItem createMockChatItem({
  required String roomId,
  required String displayName,
  String? notificationMode,
  List<String>? activeMembersIds,
  bool? isDm,
  bool? isBookmarked,
  int? unreadNotificationCount,
  int? unreadMentions,
  int? unreadMessages,
  List<MockUser>? typingUsers,
  List<MockTimelineEventItem>? timelineEventItems,
}) {
  return MockChatItem(
    roomId: roomId,
    typingUsers: typingUsers,
    mockRoom: MockRoom(
      mockRoomId: roomId,
      mockDisplayName: displayName,
      mockNotificationMode: notificationMode ?? 'all',
      mockActiveMembersIds: activeMembersIds ?? [],
    ),
    mockConvo: MockConvo(
      mockConvoId: roomId,
      mockIsDm: isDm ?? false,
      mockIsBookmarked: isBookmarked ?? false,
      mockNumUnreadNotificationCount: unreadNotificationCount ?? 0,
      mockNumUnreadMentions: unreadMentions ?? 0,
      mockNumUnreadMessages: unreadMessages ?? 0,
      mockTimelineItem: MockTimelineItem(
        mockTimelineEventItem: timelineEventItems?.last,
      ),
      mockTimelineStream: MockTimelineStream(
        mockTimelineItemDiffs: [
          MockTimelineItemDiff(
            mockAction: 'Append',
            mockTimelineItemList: MockFfiListTimelineItem(
              timelineItems:
                  timelineEventItems
                      ?.map((e) => MockTimelineItem(mockTimelineEventItem: e))
                      .toList() ??
                  [],
            ),
            mockIndex: 0,
            mockTimelineItem: MockTimelineItem(
              mockTimelineEventItem: timelineEventItems?.last,
            ),
          ),
        ],
      ),
    ),
  );
}

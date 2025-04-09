import 'package:acter/features/chat_ui_showcase/models/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_room.dart';

class MockChatItem {
  final String roomId;
  final MockRoom mockRoom;
  final MockConvo mockConvo;

  MockChatItem({
    required this.roomId,
    required this.mockRoom,
    required this.mockConvo,
  });
}

MockChatItem createMockChatItem({
  required String roomId,
  required String displayName,
  required String notificationMode,
  required List<String> activeMembersIds,
  required bool isDm,
  required bool isBookmarked,
  required int unreadNotificationCount,
  required int unreadMentions,
  required int unreadMessages,
  required MockTimelineEventItem timelineEventItem,
}) {
  return MockChatItem(
    roomId: roomId,
    mockRoom: MockRoom(
      mockRoomId: roomId,
      mockDisplayName: displayName,
      mockNotificationMode: notificationMode,
      mockActiveMembersIds: activeMembersIds,
    ),
    mockConvo: MockConvo(
      mockConvoId: roomId,
      mockIsDm: isDm,
      mockIsBookmarked: isBookmarked,
      mockNumUnreadNotificationCount: unreadNotificationCount,
      mockNumUnreadMentions: unreadMentions,
      mockNumUnreadMessages: unreadMessages,
      mockTimelineItem: MockTimelineItem(
        mockTimelineEventItem: timelineEventItem,
      ),
    ),
  );
}

final mockChatItem1 = createMockChatItem(
  roomId: 'mock-room-1',
  displayName: 'Emily Davis',
  notificationMode: 'muted',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  isDm: true,
  isBookmarked: true,
  unreadNotificationCount: 4,
  unreadMentions: 2,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1744182966000, // April 9, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Hey, whats the update?'),
  ),
);

final mockChatItem2 = createMockChatItem(
  roomId: 'mock-room-2',
  displayName: 'Product Team',
  notificationMode: 'muted',
  activeMembersIds: [
    '@sarah:acter.global',
    '@michael:acter.global',
    '@lisa:acter.global',
    '@alex:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 2,
  unreadMentions: 0,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1744096566000, // April 8, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Deployment tomorrow at 2 PM. Review checklist.',
    ),
  ),
);

final mockChatItem3 = createMockChatItem(
  roomId: 'mock-room-3',
  displayName: 'Engineering',
  notificationMode: 'all',
  activeMembersIds: [
    '@robert:acter.global',
    '@jennifer:acter.global',
    '@david:acter.global',
    '@patricia:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 2,
  unreadMentions: 0,
  unreadMessages: 2,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@robert:acter.global',
    mockOriginServerTs: 1744010166000, // April 7, 2025
    mockMsgContent: MockMsgContent(mockBody: 'CI/CD fixed. Tests passing.'),
  ),
);

final mockChatItem4 = createMockChatItem(
  roomId: 'mock-room-4',
  displayName: 'Design Review',
  notificationMode: 'muted',
  activeMembersIds: [
    '@emma:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
  ],
  isDm: false,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1743923766000, // April 6, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'UI components updated. Please review.',
    ),
  ),
);

final mockChatItem5 = createMockChatItem(
  roomId: 'mock-room-5',
  displayName: 'Michael, Kumarpalsinh & Ben',
  notificationMode: 'all',
  activeMembersIds: [
    '@michael:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@michael:acter.global',
    mockOriginServerTs: 1743837366000, // April 5, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Can we schedule a quick sync about the API changes?',
    ),
  ),
);

final mockChatItem6 = createMockChatItem(
  roomId: 'mock-room-6',
  displayName: 'Sarah Wilson',
  notificationMode: 'all',
  activeMembersIds: ['@sarah:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@sarah:acter.global',
    mockOriginServerTs: 1743750966000, // April 4, 2025
    mockMsgContent: MockMsgContent(
      mockBody:
          'The meeting notes are ready. I\'ve highlighted the action items.',
    ),
  ),
);

final mockChatItem7 = createMockChatItem(
  roomId: 'mock-room-7',
  displayName: 'Project Alpha',
  notificationMode: 'all',
  activeMembersIds: [
    '@jennifer:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@jennifer:acter.global',
    mockOriginServerTs: 1743664566000, // April 3, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Sprint retro tomorrow at 11 AM.'),
  ),
);

final mockChatItem8 = createMockChatItem(
  roomId: 'mock-room-8',
  displayName: 'Lisa Park',
  notificationMode: 'all',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1743578166000, // April 2, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'The documentation is updated with the latest API changes.',
    ),
  ),
);

final mockChatItem9 = createMockChatItem(
  roomId: 'mock-room-9',
  displayName: 'Team Updates',
  notificationMode: 'all',
  activeMembersIds: [
    '@emily:acter.global',
    '@alex:acter.global',
    '@christopher:acter.global',
    '@daniel:acter.global',
  ],
  isDm: false,
  isBookmarked: true,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emily:acter.global',
    mockOriginServerTs: 1743491766000, // April 1, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'New features deployed. Monitor for issues.',
    ),
  ),
);

final mockChatItem10 = createMockChatItem(
  roomId: 'mock-room-10',
  displayName: 'Emma, Kumarpalsinh & Ben',
  notificationMode: 'all',
  activeMembersIds: [
    '@emma:acter.global',
    '@kumarpalsinh:acter.global',
    '@ben:acter.global',
  ],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@emma:acter.global',
    mockOriginServerTs: 1743405366000, // March 31, 2025
    mockMsgContent: MockMsgContent(
      mockBody:
          'Let me know when you\'re free to discuss the design system updates.',
    ),
  ),
);

final mockChatItem11 = createMockChatItem(
  roomId: 'mock-room-11',
  displayName: 'Alex Thompson',
  notificationMode: 'all',
  activeMembersIds: ['@alex:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@alex:acter.global',
    mockOriginServerTs: 1743318966000, // March 30, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'See you at the team meeting tomorrow at 10 AM.',
    ),
  ),
);

final mockChatItem12 = createMockChatItem(
  roomId: 'mock-room-12',
  displayName: 'Marketing Team',
  notificationMode: 'all',
  activeMembersIds: [
    '@christopher:acter.global',
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@christopher:acter.global',
    mockOriginServerTs: 1743232566000, // March 29, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Campaign approved. Launch next week.',
    ),
  ),
);

final mockChatItem13 = createMockChatItem(
  roomId: 'mock-room-13',
  displayName: 'Lisa Park',
  notificationMode: 'all',
  activeMembersIds: ['@lisa:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@lisa:acter.global',
    mockOriginServerTs: 1743146166000, // March 28, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Document reviewed and approved. Ready for implementation.',
    ),
  ),
);

final mockChatItem14 = createMockChatItem(
  roomId: 'mock-room-14',
  displayName: 'Product Feedback',
  notificationMode: 'all',
  activeMembersIds: [
    '@daniel:acter.global',
    '@james:acter.global',
    '@patricia:acter.global',
    '@david:acter.global',
  ],
  isDm: false,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@daniel:acter.global',
    mockOriginServerTs: 1743059766000, // March 27, 2025
    mockMsgContent: MockMsgContent(mockBody: 'Feature requests prioritized.'),
  ),
);

final mockChatItem15 = createMockChatItem(
  roomId: 'mock-room-15',
  displayName: 'David Miller',
  notificationMode: 'all',
  activeMembersIds: ['@david:acter.global', '@kumarpalsinh:acter.global'],
  isDm: true,
  isBookmarked: false,
  unreadNotificationCount: 0,
  unreadMentions: 0,
  unreadMessages: 0,
  timelineEventItem: MockTimelineEventItem(
    mockSenderId: '@david:acter.global',
    mockOriginServerTs: 1742973366000, // March 26, 2025
    mockMsgContent: MockMsgContent(
      mockBody: 'Task completed and merged to main branch.',
    ),
  ),
);

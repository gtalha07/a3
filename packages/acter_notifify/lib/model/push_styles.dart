//LIST OF PUSH STYLE EMOJIS
enum PushStyles {
  //Related things
  comment('💬'),
  reaction('❤️'),
  attachment('📎'),
  references('🔗'),

  //Event Change
  eventDateChange('🕒'),
  rsvpYes('✅'),
  rsvpMaybe('✔️'),
  rsvpNo('✖️'),

  //Task-list
  taskAdd('➕'),

  //Task
  taskComplete('🟢'),
  taskReOpen('  ⃝ '),
  taskAccept('🤝'),
  taskDecline('✖️'),
  taskDueDateChange('🕒'),
  objectInvitation('📨'),

  //General
  titleChange('✏️'),
  descriptionChange('✏️'),
  creation('➕'),
  redaction('🗑️'),
  otherChanges('✏️'),

  //Space Name
  roomName('✏️'),
  roomTopic('✏️'),
  roomAvatar('👤'),

  invitationAccepted('✅'),
  invitationRejected('❌'),
  invitationRevoked('❌'),
  knockAccepted('👋'),
  knockRetracted('👋'),
  knockDenied('👋'),
  invited('📨'),
  joined('🤝'),
  left('👋'),
  knocked('👋'),
  kicked('👋'),
  kickedAndBanned('👋'),
  banned('👋'),
  unbanned('👋');

  const PushStyles(this.emoji);

  final String emoji;
}

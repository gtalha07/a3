import 'package:acter_notifify/data_contants/data_contants.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_data/mock_notification_item.dart';
import 'mock_data/mock_notification_parent.dart';
import 'mock_data/mock_notification_sender.dart';

void main() {
  late MockNotificationItem item;
  late MockNotificationParent parent;
  late MockMsgContent msg;

  setUpAll(() {
    //Mack declaration
    item = MockNotificationItem();
    parent = MockNotificationParent();

    //Set parent
    when(() => item.parent()).thenReturn(parent);

    //Set pushStyle
    when(() => item.pushStyle()).thenReturn(PushStyles.comment.name);

    //Set send user name
    final sender = MockNotificationSender(name: "Washington Johnson");
    when(() => item.sender()).thenReturn(sender);

    //Set message content
    msg = MockMsgContent(content: "This is great");
    when(() => item.body()).thenReturn(msg);
  });

  group("Title and body generation", () {
    test("Comment on boost", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(ObjectType.news.name);
      when(() => parent.emoji()).thenReturn(ObjectEmoji.news.data);

      // Act: process data and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Comment on 🚀 boost");
      expect(body, "Washington Johnson: This is great");
    });

    test("Comment on Pin", () {
      // Arrange: Set parent object data
      when(() => parent.objectTypeStr()).thenReturn(ObjectType.pin.name);
      when(() => parent.emoji()).thenReturn(ObjectEmoji.pin.data);

      // Act: process data and get tile and body
      when(() => parent.title()).thenReturn("The house");
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Comment on 📌 The house");
      expect(body, "Washington Johnson: This is great");
    });

    test("Comment with no parent", () {
      // Arrange: Set sender and parent object data
      final sender = MockNotificationSender(
          username: "@id:acter.global"); // no display name
      when(() => item.sender()).thenReturn(sender);
      when(() => item.parent()).thenReturn(null);

      // Act: process data and get tile and body
      final (title, body) = genTitleAndBody(item);

      // Assert: Check if tile and body are as expected
      expect(title, "💬 Comment");
      expect(body, "@id:acter.global: This is great");
    });
  });
}

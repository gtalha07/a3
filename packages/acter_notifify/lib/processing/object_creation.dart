import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectCreation(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final spaceName = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final title = getObjectCentricTitlePart(parent, 'created');
    final body = 'by $username in "$spaceName"';
    return (title, body);
  } else {
    final title = '$username created object in "$spaceName"';
    return (title, null);
  }
}

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectTitleChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newTitle = notification.title();

  final title = notification.parent()?.getObjectCentricTitlePart('renamed');
  if (title != null) {
    final body = 'by $username to "$newTitle"';
    return (title, body);
  } else {
    final title = '$username renamed title to "$newTitle"';
    return (title, null);
  }
}

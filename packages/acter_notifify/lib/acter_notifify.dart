library acter_notifify;

import 'dart:async';
import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/local.dart';
import 'package:acter_notifify/notifications.dart';
import 'package:acter_notifify/util.dart';
import 'package:firebase_core/firebase_core.dart';

/// Function to call when a notification has been tapped by the user
typedef HandleMessageTap = FutureOr<bool> Function(Map<String?, Object?> data);

/// Function called at starting to process any notification to check whether
/// we should continue or not bother the user. Just a user based switch
typedef IsEnabledCheck = FutureOr<bool> Function();

/// Given the target url of the notifiction, should this notification be shown
/// or just be ignored. Useful to avoid showing push notification if the user
/// is on that same screen
typedef ShouldShowCheck = FutureOr<bool> Function(String url);

/// When we get a new token, we inform all clients about this. We call this callback
/// to get a list of currently activated clients.
typedef CurrentClientsGen = FutureOr<List<Client>> Function();

/// Initialize Notification support
Future<void> initializeNotifify({
  FirebaseOptions? androidFirebaseOptions,
  HandleMessageTap? handleMessageTap,
  IsEnabledCheck? isEnabledCheck,
  ShouldShowCheck? shouldShowCheck,
  CurrentClientsGen? currentClientsGen,
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: androidFirebaseOptions,
    );
  }
  await initializeLocalNotifications();

  if (usePush && handleMessageTap != null) {
    await initializePush(
      handleMessageTap: handleMessageTap,
      shouldShowCheck: shouldShowCheck,
      isEnabledCheck: isEnabledCheck,
      currentClientsGen: currentClientsGen,
      appIdPrefix: appIdPrefix,
      appName: appName,
      pushServerUrl: pushServerUrl,
    );
  }
}

/// Return false if the user declined the request to
/// allow notification, null if no token was found and
/// true if the token was successfully committed along
/// side the pushserver
Future<bool?> setupNotificationsForDevice(
  Client client, {
  required String appName,
  required String appIdPrefix,
  required String pushServerUrl,
}) async {
  if (usePush) {
    return await setupPushNotificationsForDevice(client,
        appIdPrefix: appIdPrefix,
        appName: appName,
        pushServerUrl: pushServerUrl);
  }
  return null;
}

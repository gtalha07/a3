import 'dart:async';
import 'dart:core';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

export './effektio_flutter_sdk_ffi.dart' show Client;

// class EffektioClient extends ChangeNotifier {
//   final Client client;
//   EffektioClient(this.client);
// }

const defaultServerUrl = String.fromEnvironment(
  'DEFAULT_HOMESERVER_URL',
  defaultValue: 'https://matrix.effektio.org',
);

const defaultServerName = String.fromEnvironment(
  'DEFAULT_HOMESERVER_NAME',
  defaultValue: 'effektio.org',
);

const logSettings = String.fromEnvironment(
  'RUST_LOG',
  defaultValue: 'warn,effektio=debug',
);

const defaultSessionKey = String.fromEnvironment(
  'DEFAULT_EFFEKTIO_SESSION',
  defaultValue: 'sessions',
);

// ex: a3-nightly or effektio-linux
String appName = String.fromEnvironment(
  'APP_NAME',
  defaultValue: 'effektio-${Platform.operatingSystem}',
);

const versionName = String.fromEnvironment(
  'VERSION_NAME',
  defaultValue: 'DEV',
);

String userAgent = '$appName/$versionName';

Color convertColor(ffi.EfkColor? primary, Color fallback) {
  if (primary == null) {
    return fallback;
  }
  var data = primary.rgbaU8();
  return Color.fromARGB(
    data[3],
    data[0],
    data[1],
    data[2],
  );
}

class EffektioSdk {
  static EffektioSdk? _instance;
  late final ffi.Api _api;
  static String _sessionKey = defaultSessionKey;
  final int _index = 0;
  static final List<ffi.Client> _clients = [];
  static const platform = MethodChannel('effektio_flutter_sdk');

  EffektioSdk._(this._api);

  Future<void> _persistSessions() async {
    List<String> sessions = [];
    for (var c in _clients) {
      String token = await c.restoreToken();
      sessions.add(token);
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sessionKey, sessions);
  }

  static Future<void> resetSessionsAndClients(String sessionKey) async {
    await _unrestoredInstance;
    _clients.clear();
    _sessionKey = sessionKey;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sessionKey, []);
  }

  Future<void> _restore() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> sessions = (prefs.getStringList(_sessionKey) ?? []);
    bool loggedIn = false;
    for (var token in sessions) {
      ffi.Client client = await _api.loginWithToken(appDocPath, token);
      _clients.add(client);
      loggedIn = client.loggedIn();
    }

    if (_clients.isEmpty) {
      ffi.Client client = await _api.guestClient(
        appDocPath,
        defaultServerName,
        defaultServerUrl,
        userAgent,
      );
      _clients.add(client);
      loggedIn = client.loggedIn();
      await _persistSessions();
    }
    debugPrint('Restored $_clients: $loggedIn');
  }

  ffi.Client get currentClient {
    return _clients[_index];
  }

  bool get hasClients {
    return _clients.isNotEmpty;
  }

  static Future<String> _getNativeLibraryDirectory() async {
    String libDir;
    try {
      libDir = await platform.invokeMethod('getNativeLibraryDirectory');
    } on PlatformException {
      libDir = '';
    }
    return libDir;
  }

  static Future<DynamicLibrary> _getAndroidDynLib(String libName) async {
    try {
      // android api 30 is working here
      return DynamicLibrary.open(libName);
    } catch (_) {
      try {
        // android api 23 is working here
        final String? nativeLibDir = await _getNativeLibraryDirectory();
        return DynamicLibrary.open('$nativeLibDir/$libName');
      } catch (_) {
        try {
          final PackageInfo pkgInfo = await PackageInfo.fromPlatform();
          final String pkgName = pkgInfo.packageName;
          return DynamicLibrary.open('/data/data/$pkgName/$libName');
        } catch (_) {
          rethrow;
        }
      }
    }
  }

  static Future<EffektioSdk> get _unrestoredInstance async {
    if (_instance == null) {
      final api = Platform.isAndroid
          ? ffi.Api(await _getAndroidDynLib('libeffektio.so'))
          : ffi.Api.load();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      try {
        api.initLogging(appDocDir.path, logSettings);
      } catch (e) {
        developer.log(
          'Logging setup failed',
          level: 900, // warning
          error: e,
        );
      }
      _instance = EffektioSdk._(api);
    }
    return _instance!;
  }

  static Future<EffektioSdk> get instance async {
    final instance = await _unrestoredInstance;
    if (!instance.hasClients) {
      await instance._restore();
    }
    return instance;
  }

  Future<ffi.Client> login(String username, String password) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.loginNewClient(
      appDocPath,
      username,
      password,
      defaultServerName,
      defaultServerUrl,
      userAgent,
    );
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      var client = _clients.removeAt(0);
      unawaited(
        client.logout().catchError((e) {
          developer.log(
            'Logout of Guest failed',
            level: 900, // warning
            error: e,
          );
          return e is int;
        }),
      ); // Explicitly-ignored fire-and-forget.
    }
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  Future<void> logout() async {
    // remove current client from list
    var client = _clients.removeAt(0);
    await _persistSessions();
    unawaited(
      client.logout().catchError((e) {
        developer.log(
          'Logout failed',
          level: 900, // warning
          error: e,
        );
        return e is int;
      }),
    ); // Explicitly-ignored fire-and-forget.
    if (_clients.isEmpty) {
      // login as guest
      await _restore();
    }
  }

  Future<ffi.Client> signUp(
    String username,
    String password,
    String displayName,
    String token,
  ) async {
    // To be removed when client management is implemented.
    for (final client in _clients) {
      if (client.userId().toString() == username) {
        return client;
      }
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final client = await _api.registerWithRegistrationToken(
      appDocPath,
      username,
      password,
      token,
      defaultServerName,
      defaultServerUrl,
      userAgent,
    );
    final account = client.account();
    await account.setDisplayName(displayName);
    if (_clients.length == 1 && _clients[0].isGuest()) {
      // we are replacing a guest account
      _clients.removeAt(0);
    }
    _clients.add(client);
    await _persistSessions();
    return client;
  }

  List<ffi.Client> get clients {
    return _clients;
  }

  ffi.CreateGroupSettings newGroupSettings(String name) {
    return _api.newGroupSettings(name);
  }

  String rotateLogFile() {
    return _api.rotateLogFile();
  }

  void writeLog(String text, String level) {
    _api.writeLog(text, level);
  }
}

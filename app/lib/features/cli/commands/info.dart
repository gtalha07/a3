import 'package:acter/config/env.g.dart';
import 'package:args/command_runner.dart';
import 'package:acter/features/cli/util.dart';

import 'dart:io';
// ignore_for_file: avoid_print

class InfoCommand extends Command {
  @override
  final name = 'info';
  @override
  final description = 'Local info about your acter';

  InfoCommand();

  @override
  Future<void> run() async {
    print('Acter ${Env.rageshakeAppVersion}');
    print(' - Default Homeserver: ${Env.defaultHomeserverName}');
    print(' - Default Homeserver URL: ${Env.defaultHomeserverUrl}');
    final appInfo = await AppInfo.make();
    print('Locally:');
    print(' - App Folder: ${appInfo.appDocPath}');

    if (appInfo.logFiles.isNotEmpty) {
      print(' - Latest log file: ${appInfo.logFiles[0].path}');
    }

    print(' - Number of current sessions found: ${appInfo.sessions.length}');
    if (appInfo.accounts.isNotEmpty) {
      print(' - Data of sessions found: ${appInfo.accounts.length}');
      for (final acc in appInfo.accounts) {
        print('    * $acc');
      }
    }
    exit(0);
  }
}

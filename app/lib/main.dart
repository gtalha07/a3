import 'dart:async';

import 'package:acter/config/notifications/init.dart';
import 'package:acter/common/providers/app_state_provider.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/tutorial_dialogs/bottom_navigation_tutorials/bottom_navigation_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/space_overview_tutorials.dart';
import 'package:acter/common/utils/language.dart';
import 'package:acter/common/utils/logging.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/features/cli/main.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    await cliMain(args);
  } else {
    await _startAppInner(makeApp(), true);
  }
}

Widget makeApp() {
  return const ProviderScope(child: Acter());
}

Future<void> startAppForTesting(Widget app) async {
  // make sure our test isn't distracted by the onboarding wizzards
  setCreateOrJoinSpaceTutorialAsViewed();
  setBottomNavigationTutorialsAsViewed();
  setSpaceOverviewTutorialsAsViewed();
  return await _startAppInner(app, false);
}

Future<void> _startAppInner(Widget app, bool withSentry) async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoPlayerMediaKit.ensureInitialized(
    android: true,
    iOS: true,
    macOS: true,
    windows: true,
    linux: true,
  );
  await initializeNotifications();
  await initLogging();
  if (withSentry) {
    await SentryFlutter.init(
      (options) {
        // we use the dart-define default env for the default stuff.
        options.dsn =
            const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
        options.environment = const String.fromEnvironment(
          'SENTRY_ENVIRONMENT',
          defaultValue: '',
        );
        options.release =
            const String.fromEnvironment('SENTRY_RELEASE', defaultValue: '');

        // allows us to check whether the user has activated tracing
        // and prevent reporting otherwise.
        options.beforeSend = sentryBeforeSend;
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}

class Acter extends ConsumerStatefulWidget {
  const Acter({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ActerState();
}

class _ActerState extends ConsumerState<Acter> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    initLanguage(ref);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState newState) {
    ref.read(appStateProvider.notifier).update((state) => newState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    // all toast msgs will appear at bottom
    final builder = EasyLoading.init();
    EasyLoading.instance.toastPosition = EasyLoadingToastPosition.bottom;

    return Portal(
      child: MaterialApp.router(
        routerConfig: router,
        theme: ActerTheme.theme,
        title: 'Acter',
        builder: builder,
        locale: Locale(language),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        // MaterialApp contains our top-level Navigator
      ),
    );
  }
}

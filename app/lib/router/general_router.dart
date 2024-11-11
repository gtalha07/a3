import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/pages/fatal_fail.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/avatar/full_screen_avatar_page.dart';
import 'package:acter/common/widgets/dialog_page.dart';
import 'package:acter/common/widgets/side_sheet_page.dart';
import 'package:acter/features/auth/pages/forgot_password.dart';
import 'package:acter/features/auth/pages/login_page.dart';
import 'package:acter/features/auth/pages/register_page.dart';
import 'package:acter/features/bug_report/pages/bug_report_page.dart';
import 'package:acter/features/chat/widgets/create_chat.dart';
import 'package:acter/features/deep_linking/pages/scan_qr_code.dart';
import 'package:acter/features/intro/pages/intro_page.dart';
import 'package:acter/features/intro/pages/intro_profile.dart';
import 'package:acter/features/news/pages/add_news_page.dart';
import 'package:acter/features/onboarding/pages/analytics_opt_in_page.dart';
import 'package:acter/features/onboarding/pages/link_email_page.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/upload_avatar_page.dart';
import 'package:acter/features/pins/pages/create_pin_page.dart';
import 'package:acter/features/space/sheets/link_room_sheet.dart';
import 'package:acter/features/super_invites/pages/create.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final generalRoutes = [
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.forward.name,
    path: Routes.forward.route,
    redirect: forwardRedirect,
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.intro.name,
    path: Routes.intro.route,
    builder: (context, state) => const IntroPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.introProfile.name,
    path: Routes.introProfile.route,
    builder: (context, state) => const IntroProfile(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.authLogin.name,
    path: Routes.authLogin.route,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.forgotPassword.name,
    path: Routes.forgotPassword.route,
    builder: (context, state) => const ForgotPassword(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.authRegister.name,
    path: Routes.authRegister.route,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.saveUsername.name,
    path: Routes.saveUsername.route,
    builder: (context, state) {
      final username = state.uri.queryParameters['username']
          .expect('saveUsername route needs username as query param');
      return SaveUsernamePage(username: username);
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.scanQrCode.name,
    path: Routes.scanQrCode.route,
    builder: (context, state) => const ScanQrCode(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.linkEmail.name,
    path: Routes.linkEmail.route,
    builder: (context, state) => LinkEmailPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.uploadAvatar.name,
    path: Routes.uploadAvatar.route,
    builder: (context, state) => UploadAvatarPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.analyticsOptIn.name,
    path: Routes.analyticsOptIn.route,
    builder: (context, state) => const AnalyticsOptInPage(),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.bugReport.name,
    path: Routes.bugReport.route,
    pageBuilder: (context, state) => DialogPage(
      builder: (BuildContext context) {
        final screenshot = state.uri.queryParameters['screenshot'];
        final error = state.uri.queryParameters['error'];
        final stack = state.uri.queryParameters['stack'];
        return BugReportPage(
          imagePath: screenshot,
          error: error,
          stack: stack,
        );
      },
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.fatalFail.name,
    path: Routes.fatalFail.route,
    builder: (context, state) {
      final error = state.uri.queryParameters['error']
          .expect('fatalFail route needs error query param');
      final trace = state.uri.queryParameters['trace']
          .expect('fatalFail route needs trace query param');
      return FatalFailPage(
        error: error,
        trace: trace,
      );
    },
  ),
  GoRoute(
    name: Routes.createPin.name,
    path: Routes.createPin.route,
    pageBuilder: (context, state) {
      final spaceId = state.uri.queryParameters['spaceId'];
      return NoTransitionPage(
        key: state.pageKey,
        child: CreatePinPage(
          initialSelectedSpace: spaceId?.isNotEmpty == true ? spaceId : null,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.actionCreateSuperInvite.name,
    path: Routes.actionCreateSuperInvite.route,
    pageBuilder: (context, state) {
      final token = state.extra as SuperInviteToken?;
      return SideSheetPage(
        key: state.pageKey,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
        child: CreateSuperInviteTokenPage(token: token),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.linkChat.name,
    path: Routes.linkChat.route,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('linkChat route needs spaceId as path param');
      return SideSheetPage(
        key: state.pageKey,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
        child: LinkRoomPage(
          parentSpaceId: spaceId,
          pageTitle: 'Link as Space-chat',
          childRoomType: ChildRoomType.chat,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.linkSubspace.name,
    path: Routes.linkSubspace.route,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('linkSubspace route needs spaceId as path param');
      return SideSheetPage(
        key: state.pageKey,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
        child: LinkRoomPage(
          parentSpaceId: spaceId,
          pageTitle: 'Link Sub-Space',
          childRoomType: ChildRoomType.space,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.linkRecommended.name,
    path: Routes.linkRecommended.route,
    pageBuilder: (context, state) {
      final spaceId = state.pathParameters['spaceId']
          .expect('linkRecommended route needs spaceId as path param');
      return SideSheetPage(
        key: state.pageKey,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
        child: LinkRoomPage(
          parentSpaceId: spaceId,
          pageTitle: 'Link Recommended-Space',
          childRoomType: ChildRoomType.recommendedSpace,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.actionAddUpdate.name,
    path: Routes.actionAddUpdate.route,
    redirect: authGuardRedirect,
    pageBuilder: (context, state) {
      final spaceId = state.uri.queryParameters['spaceId'];
      return NoTransitionPage(
        key: state.pageKey,
        child: AddNewsPage(
          initialSelectedSpace: spaceId?.isNotEmpty == true ? spaceId : null,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.createChat.name,
    path: Routes.createChat.route,
    pageBuilder: (context, state) {
      final spaceId = state.uri.queryParameters['spaceId'];
      final page = state.extra as int?;
      return context.isLargeScreen
          ? DialogPage(
              barrierDismissible: false,
              builder: (context) => CreateChatPage(
                initialSelectedSpaceId: spaceId,
                initialPage: page,
              ),
            )
          : CustomTransitionPage(
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final tween = Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut));
                final offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              child: CreateChatPage(
                initialSelectedSpaceId: spaceId,
                initialPage: page,
              ),
            );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.fullScreenAvatar.name,
    path: Routes.fullScreenAvatar.route,
    pageBuilder: (context, state) {
      final roomId = state.uri.queryParameters['roomId']
          .expect('fullScreenAvatar route needs roomId as query param');
      return NoTransitionPage(
        key: state.pageKey,
        child: FullScreenAvatarPage(roomId: roomId),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavKey,
    name: Routes.main.name,
    path: Routes.main.route,
    redirect: (BuildContext context, GoRouterState state) async {
      // we first check if there is a client available for us to use
      final authGuarded = await authGuardRedirect(context, state);
      if (authGuarded != null) {
        return authGuarded;
      }
      if (context.mounted && isDesktop) {
        return Routes.dashboard.route;
      } else {
        return Routes.updates.route;
      }
    },
  ),
];

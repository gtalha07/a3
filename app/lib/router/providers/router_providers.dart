import 'package:acter/common/widgets/error.dart';
import 'package:acter/router/providers/notifiers/router_notifier.dart';
import 'package:acter/router/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: implementation_imports
import 'package:go_router/src/information_provider.dart';

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(() {
  return RouterNotifier();
});

final goRouterProvider = Provider.autoDispose<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider.notifier);
  return GoRouter(
    errorBuilder: (context, state) => ErrorPage(routerState: state),
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: notifier.routeList,
  );
});

final routeInformationProvider =
    ChangeNotifierProvider.autoDispose<GoRouteInformationProvider>((ref) {
  final router = ref.watch(goRouterProvider);
  return router.routeInformationProvider;
});

final currentRoutingLocation = Provider.autoDispose<String>((ref) {
  return ref.watch(routeInformationProvider).value.location ?? '/';
});
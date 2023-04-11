import 'package:acter/features/onboarding/states/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void confirmationDialog(BuildContext ctx, WidgetRef ref) {
  showDialog(
    context: ctx,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(
          'Logout',
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => ref.read(authStateProvider.notifier).logOut(ctx),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}

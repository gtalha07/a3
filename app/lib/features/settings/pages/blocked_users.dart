import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::blocked_users');

class AddUserToBlock extends StatefulWidget {
  const AddUserToBlock({super.key});

  @override
  State<AddUserToBlock> createState() => _AddUserToBlockState();
}

class _AddUserToBlockState extends State<AddUserToBlock> {
  final TextEditingController userName = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'blocked user form');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).blockUserWithUsername),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: userName,
                // required field, custom format
                validator: (val) =>
                    val == null || !val.startsWith('@') || !val.contains(':')
                        ? L10n.of(context).formatMustBe
                        : null,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, userName.text);
          },
          child: Text(L10n.of(context).block),
        ),
      ],
    );
  }
}

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersLoader = ref.watch(ignoredUsersProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(L10n.of(context).blockedUsers),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Atlas.plus_circle_thin),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async => await onAdd(context, ref),
            ),
          ],
        ),
        body: usersLoader.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Text(L10n.of(context).hereYouCanSeeAllUsersYouBlocked),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverList.builder(
                  itemBuilder: (BuildContext context, int index) {
                    final userId = users[index].toString();
                    return Card(
                      margin: const EdgeInsets.all(5),
                      child: ListTile(
                        title: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(userId),
                        ),
                        trailing: OutlinedButton(
                          child: Text(L10n.of(context).unblock),
                          onPressed: () async => await onDelete(
                            context,
                            ref,
                            userId,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: users.length,
                ),
              ],
            );
          },
          error: (e, s) {
            _log.severe('Failed to load the ignored users', e, s);
            return Center(
              child: Text(L10n.of(context).loadingFailed(e)),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Future<void> onAdd(BuildContext context, WidgetRef ref) async {
    final userToAdd = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) => const AddUserToBlock(),
    );
    if (userToAdd == null) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: L10n.of(context).blockingUserProgress);
    try {
      final account = ref.read(accountProvider);
      await account.ignoreUser(userToAdd);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).userAddedToBlockList(userToAdd));
    } catch (e, s) {
      _log.severe('Failed to block user', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).blockingUserFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onDelete(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    EasyLoading.show(status: L10n.of(context).unblockingUser);
    try {
      final account = ref.read(accountProvider);
      await account.unignoreUser(userId);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).userRemovedFromList);
    } catch (e, s) {
      _log.severe('Failed to unblock user', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).unblockingUserFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

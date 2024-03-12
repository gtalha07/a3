import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/profile/widgets/skeletons/my_profile_skeletons_widget.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangeDisplayName extends StatefulWidget {
  final AccountProfile account;

  const ChangeDisplayName({
    super.key,
    required this.account,
  });

  @override
  State<ChangeDisplayName> createState() => _ChangeDisplayNameState();
}

class _ChangeDisplayNameState extends State<ChangeDisplayName> {
  final TextEditingController newUsername = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    newUsername.text = widget.account.profile.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return AlertDialog(
      title: const Text('Change your display name'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(controller: newUsername),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final currentUserName = account.profile.displayName;
              final newDisplayName = newUsername.text;
              if (currentUserName != newDisplayName) {
                Navigator.pop(context, newDisplayName);
              } else {
                Navigator.pop(context, null);
              }
              return;
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class MyProfilePage extends StatelessWidget {
  static const displayNameKey = Key('my-profile-display-name');

  const MyProfilePage({super.key});

  Future<void> updateDisplayName(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final TextEditingController newName = TextEditingController();
    newName.text = profile.profile.displayName ?? '';

    final newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => ChangeDisplayName(account: profile),
    );

    if (newText != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Updating Display Name',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      await profile.account.setDisplayName(newText);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'Display Name update submitted');
    }
  }

  Future<void> updateAvatar(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      EasyLoading.show(status: 'Updating profile image');

      final file = result.files.first;
      await profile.account.uploadAvatar(file.path!);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      // close loading
      EasyLoading.dismiss();
    } else {
      // user cancelled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: _buildAppbar(context),
        body: _buildBody(context),
      ),
    );
  }

  AppBar _buildAppbar(BuildContext context) {
    return AppBar(
      title: Text(
        'Profile',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final account = ref.watch(accountProfileProvider);

        return account.when(
          data: (data) {
            final userId = data.account.userId().toString();
            final displayName = data.profile.displayName ?? '';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildAvatarUI(context, ref, data),
                    const SizedBox(height: 20),
                    _profileItem(
                      key: MyProfilePage.displayNameKey,
                      context: context,
                      title: 'Display Name',
                      subTitle: displayName,
                      trailingIcon: Atlas.pencil_edit,
                      onPressed: () => updateDisplayName(data, context, ref),
                    ),
                    const SizedBox(height: 20),
                    _profileItem(
                      context: context,
                      title: 'Username',
                      subTitle: userId,
                      trailingIcon: Atlas.pages,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: userId),
                        );
                        customMsgSnackbar(
                          context,
                          'Username copied to clipboard',
                        );
                      },
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            );
          },
          error: (e, trace) => Text('error: $e'),
          loading: () => const MyProfileSkeletonWidget(),
        );
      },
    );
  }

  Widget _buildAvatarUI(BuildContext context, WidgetRef ref, data) {
    return GestureDetector(
      onTap: () => updateAvatar(data, context, ref),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: Stack(
            children: [
              ActerAvatar(
                mode: DisplayMode.DM,
                avatarInfo: AvatarInfo(
                  uniqueId: data.account.userId().toString(),
                  avatar: data.profile.getAvatarImage(),
                  displayName: data.profile.displayName,
                ),
                size: 50,
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileItem({
    Key? key,
    required BuildContext context,
    required String title,
    required String subTitle,
    required IconData trailingIcon,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          child: Text(
            subTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        trailing: IconButton(
          onPressed: onPressed,
          icon: Icon(trailingIcon),
        ),
      ),
    );
  }
}

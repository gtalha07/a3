import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/checkbox_form_field.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::super_invites::create');

class CreateSuperInviteTokenPage extends ConsumerStatefulWidget {
  static Key tokenFieldKey = const Key('super-invites-create-token-token');
  static Key createDmKey = const Key('super-invites-create-token-create-dm');
  static Key addSpaceKey = const Key('super-invites-create-token-add-space');
  static Key addSubmenu = const Key('super-invites-create-token-add-submenu');
  static Key addChatKey = const Key('super-invites-create-token-add-chat');
  static Key submitBtn = const Key('super-invites-create-submitBtn');
  static Key deleteBtn = const Key('super-invites-create-delete');
  static Key deleteConfirm = const Key('super-invites-create-delete-confirm');

  final SuperInviteToken? token;

  const CreateSuperInviteTokenPage({super.key, this.token});

  @override
  ConsumerState<CreateSuperInviteTokenPage> createState() =>
      _CreateSuperInviteTokenPageConsumerState();
}

class _CreateSuperInviteTokenPageConsumerState
    extends ConsumerState<CreateSuperInviteTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'create super invites form');
  late SuperInvitesTokenUpdateBuilder tokenUpdater;
  bool isEdit = false;
  int _acceptedCount = 0;
  bool _initialDmCheck = false;
  List<String> _roomIds = [];

  @override
  void initState() {
    super.initState();
    final provider = ref.read(superInvitesProvider);
    if (widget.token != null) {
      // given an update builder we are in an edit mode

      isEdit = true;
      final token = widget.token!;
      _tokenController.text = token.token();
      _roomIds = asDartStringList(token.rooms());
      _acceptedCount = token.acceptedCount();
      _initialDmCheck = token.createDm();
      tokenUpdater = token.updateBuilder();
    } else {
      tokenUpdater = provider.newTokenUpdater();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaces = List<String>.empty(growable: true);
    final chats = List<String>.empty(growable: true);
    for (final roomId in _roomIds) {
      final room = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
      if (room?.isSpace() == true) {
        spaces.add(roomId);
      } else {
        chats.add(roomId);
      }
    }
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 15),
                isEdit
                    ? ListTile(
                        title: Text(_tokenController.text),
                        subtitle: Text(
                          L10n.of(context).claimedTimes(_acceptedCount),
                        ),
                        trailing: IconButton(
                          key: CreateSuperInviteTokenPage.deleteBtn,
                          icon: const Icon(Atlas.trash_can_thin),
                          onPressed: () => _deleteIt(context),
                        ),
                      )
                    : InputTextField(
                        hintText: L10n.of(context).code,
                        key: CreateSuperInviteTokenPage.tokenFieldKey,
                        textInputType: TextInputType.text,
                        controller: _tokenController,
                        // required field
                        validator: (val) => val == null || val.length < 6
                            ? L10n.of(context).codeMustBeAtLeast6CharactersLong
                            : null,
                      ),
                CheckboxFormField(
                  key: CreateSuperInviteTokenPage.createDmKey,
                  title: Text(L10n.of(context).createDMWhenRedeeming),
                  onChanged: (newValue) =>
                      setState(() => tokenUpdater.createDm(newValue ?? false)),
                  initialValue: _initialDmCheck,
                ),
                const SizedBox(height: 10),
                ..._spacesSection(context, spaces),
                ..._chatsSection(context, chats),
                const SizedBox(
                  height: 10,
                ),
                const Divider(),
                const SizedBox(
                  height: 10,
                ),
                _actionBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _spacesSection(BuildContext context, List<String> rooms) {
    return _renderSection(
        context, L10n.of(context).spaces, L10n.of(context).addSpace, rooms,
        () async {
      final newSpace = await selectSpaceDrawer(
        context: context,
        currentSpaceId: null,
        canCheck: 'CanInvite',
        title: Text(L10n.of(context).addSpace),
      );
      if (newSpace != null) {
        if (!_roomIds.contains(newSpace)) {
          tokenUpdater.addRoom(newSpace);
          setState(
            () => _roomIds = List.from(_roomIds)..add(newSpace),
          );
        }
      }
    });
  }

  List<Widget> _chatsSection(BuildContext context, List<String> rooms) {
    return _renderSection(
        context, L10n.of(context).chats, L10n.of(context).addChat, rooms,
        () async {
      final newSpace = await selectChatDrawer(
        context: context,
        currentChatId: null,
        canCheck: 'CanInvite',
        title: Text(L10n.of(context).addChat),
      );
      if (newSpace != null) {
        if (!_roomIds.contains(newSpace)) {
          tokenUpdater.addRoom(newSpace);
          setState(
            () => _roomIds = List.from(_roomIds)..add(newSpace),
          );
        }
      }
    });
  }

  List<Widget> _renderSection(
    BuildContext context,
    String title,
    String addLabel,
    List<String> rooms,
    VoidCallback onAdd,
  ) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (rooms.isNotEmpty)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Atlas.plus_circle_thin),
            ),
        ],
      ),
      const SizedBox(
        height: 10,
      ),
      if (rooms.isNotEmpty)
        _roomsList(context, rooms)
      else
        Center(
          child: OutlinedButton.icon(
            onPressed: onAdd,
            label: Text(addLabel),
            icon: const Icon(Atlas.plus_circle_thin),
          ),
        ),
    ];
  }

  Widget _roomsList(BuildContext context, List<String> rooms) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, idx) {
        final roomId = rooms[idx];
        return RoomCard(
          roomId: roomId,
          trailing: InkWell(
            onTap: () {
              tokenUpdater.removeRoom(roomId);
              setState(
                () => _roomIds = List.from(_roomIds)..remove(roomId),
              );
            },
            child: Icon(
              Atlas.trash_can_thin,
              key: Key('room-to-invite-$roomId-remove'),
            ),
          ),
        );
      },
      itemCount: rooms.length,
    );
  }

  Widget _actionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () async {
            if (!await Navigator.maybePop(context)) {
              if (context.mounted) {
                // fallback to go to home
                context.go(Routes.main.name);
              }
            }
          },
          child: Text(
            L10n.of(context).cancel,
          ),
        ),
        const SizedBox(width: 10),
        ActerPrimaryActionButton(
          key: CreateSuperInviteTokenPage.submitBtn,
          onPressed: _submit,
          child: Text(
            isEdit ? L10n.of(context).save : L10n.of(context).createCode,
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        isEdit
            ? L10n.of(context).editInviteCode
            : L10n.of(context).createInviteCode,
      ),
    );
  }

  Future<void> _submit() async {
    final status =
        isEdit ? L10n.of(context).savingCode : L10n.of(context).creatingCode;
    EasyLoading.show(status: status);
    try {
      final tokenTxt = _tokenController.text;
      if (tokenTxt.isNotEmpty) {
        tokenUpdater.token(tokenTxt);
      }
      // all other changes happen on the object itself;
      final provider = ref.read(superInvitesProvider);
      await provider.createOrUpdateToken(tokenUpdater);
      ref.invalidate(superInvitesTokensProvider);
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context); // pop the create sheet
    } catch (e, s) {
      if (isEdit) {
        _log.severe('Failed to change the invitation code', e, s);
      } else {
        _log.severe('Failed to create the invitation code', e, s);
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      final status = isEdit
          ? L10n.of(context).saveInviteCodeFailed(e)
          : L10n.of(context).createInviteCodeFailed(e);
      EasyLoading.showError(
        status,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _deleteIt(BuildContext context) async {
    final bool? confirm = await showAdaptiveDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context).deleteCode),
          content: Text(
            L10n.of(context).doYouWantToDeleteInviteCode,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                L10n.of(context).no,
              ),
            ),
            ActerDangerActionButton(
              key: CreateSuperInviteTokenPage.deleteConfirm,
              onPressed: () async {
                Navigator.pop(context, true);
              },
              child: Text(
                L10n.of(context).delete,
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) {
      return;
    }

    EasyLoading.show(status: L10n.of(context).deletingCode);
    try {
      final tokenTxt = _tokenController.text;
      // all other changes happen on the object itself;
      final provider = ref.read(superInvitesProvider);
      await provider.delete(tokenTxt);
      ref.invalidate(superInvitesTokensProvider);
      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.pop(context); // pop the create sheet
    } catch (e, s) {
      _log.severe('Failed to delete the invitation code', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).deleteInviteCodeFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

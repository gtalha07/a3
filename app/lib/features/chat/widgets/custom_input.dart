import 'dart:async';
import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/mention_profile_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::custom_input');

final _allowEdit = StateProvider.family.autoDispose<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider
        .select((state) => state.sendingState == SendingState.preparing),
  ),
);

final canSendProvider = FutureProvider.family<bool?, String>(
  (ref, roomId) async {
    final membership = ref.watch(roomMembershipProvider(roomId));
    return membership.valueOrNull?.canString('CanSendChatMessages');
  },
);

class CustomChatInput extends ConsumerWidget {
  static const noAccessKey = Key('custom-chat-no-access');
  static const loadingKey = Key('custom-chat-loading');
  static const sendBtnKey = Key('custom-chat-send-button');
  final String roomId;
  final void Function(bool)? onTyping;

  const CustomChatInput({required this.roomId, this.onTyping, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendProvider(roomId)).valueOrNull;
    if (canSend == null) {
      // we are still loading
      return loadingState(context);
    }
    if (canSend) {
      return _ChatInput(roomId: roomId, onTyping: onTyping);
    }

    return FrostEffect(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const SizedBox(width: 1),
              const Icon(
                Atlas.block_prohibited_thin,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                key: noAccessKey,
                L10n.of(context).chatMissingPermissionsToSend,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loadingState(BuildContext context) {
    return Skeletonizer(
      child: FrostEffect(
        child: Container(
          key: loadingKey,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Atlas.paperclip_attachment_thin,
                    size: 20,
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      style: Theme.of(context).textTheme.bodyMedium,
                      cursorColor: Theme.of(context).colorScheme.primary,
                      maxLines: 6,
                      minLines: 1,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        prefixIcon: Icon(
                          Icons.shield,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ),
                        suffixIcon: const Icon(Icons.emoji_emotions),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            width: 0.5,
                            style: BorderStyle.solid,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        hintText: L10n.of(context).newMessage,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        contentPadding: const EdgeInsets.all(15),
                        hintMaxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends ConsumerStatefulWidget {
  final String roomId;
  final void Function(bool)? onTyping;

  const _ChatInput({required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __ChatInputState();
}

class __ChatInputState extends ConsumerState<_ChatInput> {
  ActerTriggerAutoCompleteTextController textController =
      ActerTriggerAutoCompleteTextController();
  final FocusNode chatFocus = FocusNode();
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setController();
      loadDraft();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _isInputEmptyNotifier.dispose();
    super.dispose();
  }

  void _setController() {
    final Map<String, TextStyle> triggerStyles = {
      '@': TextStyle(
        color: Theme.of(context).colorScheme.onSecondary,
        height: 0.5,
        background: Paint()
          ..color = Theme.of(context).colorScheme.secondary
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      ),
    };
    textController =
        ActerTriggerAutoCompleteTextController(triggerStyles: triggerStyles);
    textController.addListener(_updateInputState);
  }

  // composer draft load state handler
  Future<void> loadDraft() async {
    final draft =
        await ref.read(chatComposerDraftProvider(widget.roomId).future);
    if (draft != null) {
      if (draft.eventId() != null) {
        final eventId = draft.eventId()!;
        final draftType = draft.draftType();
        final inputNotifier = ref.read(chatInputProvider.notifier);
        final m = ref
            .read(chatMessagesProvider(widget.roomId))
            .firstWhere((x) => x.id == eventId);
        if (draftType == 'edit') {
          inputNotifier.setEditMessage(m);
        } else if (draftType == 'reply') {
          inputNotifier.setReplyToMessage(m);
        }
      }
      textController.text = draft.plainText();
      _log.info('compose draft loaded for room: ${widget.roomId}');
    }
  }

  // listener for handling send state
  void _updateInputState() {
    _isInputEmptyNotifier.value = textController.text.trim().isEmpty;
  }

  void handleEmojiSelected(Category? category, Emoji emoji) {
    // Get cursor current position
    var cursorPos = textController.selection.base.offset;

    // Right text of cursor position
    String suffixText = textController.text.substring(cursorPos);

    // Get the left text of cursor
    String prefixText = textController.text.substring(0, cursorPos);

    int emojiLength = emoji.emoji.length;

    // Add emoji at current current cursor position
    textController.text = prefixText + emoji.emoji + suffixText;

    // Cursor move to end of added emoji character
    textController.selection = TextSelection(
      baseOffset: cursorPos + emojiLength,
      extentOffset: cursorPos + emojiLength,
    );

    // Ensure we keep the cursor up
    // frame delay to keep focus connected with keyboard.
    if (!chatFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatFocus.requestFocus();
      });
    }
  }

  void handleBackspacePressed() {
    final newValue = textController.text.characters.skipLast(1).string;
    textController.text = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMessage = ref.watch(
      chatInputProvider.select((value) => value.selectedMessage),
    );

    if (selectedMessage == null) {
      return renderMain(context);
    }

    return switch (ref.watch(
      chatInputProvider.select(
        (value) => value.selectedMessageState,
      ),
    )) {
      SelectedMessageState.replyTo => renderReplyView(context, selectedMessage),
      SelectedMessageState.edit => renderEditView(context, selectedMessage),
      SelectedMessageState.none ||
      SelectedMessageState.actions =>
        renderMain(context)
    };
  }

  Widget renderMain(BuildContext context) {
    return renderChatInputArea(context, null);
  }

  Widget renderChatInputArea(BuildContext context, Widget? child) {
    final roomId = widget.roomId;
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull ?? false;
    return Column(
      children: [
        if (child != null) child,
        FrostEffect(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => selectAttachment(
                        context: context,
                        onSelected: handleFileUpload,
                      ),
                      child: const Icon(
                        Atlas.paperclip_attachment_thin,
                        size: 20,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _TextInputWidget(
                        roomId: widget.roomId,
                        controller: textController,
                        chatFocus: chatFocus,
                        onSendButtonPressed: () => onSendButtonPressed(ref),
                        isEncrypted: isEncrypted,
                        onTyping: widget.onTyping,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isInputEmptyNotifier,
                    builder: (context, isEmpty, child) {
                      return !isEmpty
                          ? renderSendButton(context, roomId)
                          : const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (ref.watch(
          chatInputProvider.select((value) => value.emojiPickerVisible),
        ))
          EmojiPickerWidget(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 3,
            ),
            onEmojiSelected: handleEmojiSelected,
            onBackspacePressed: handleBackspacePressed,
          ),
      ],
    );
  }

  Widget renderSendButton(BuildContext context, String roomId) {
    final allowEditing = ref.watch(_allowEdit(roomId));

    if (allowEditing) {
      return IconButton.filled(
        key: CustomChatInput.sendBtnKey,
        iconSize: 20,
        onPressed: () => onSendButtonPressed(ref),
        icon: const Icon(Icons.send),
      );
    }

    return IconButton.filled(
      iconSize: 20,
      onPressed: () => {},
      icon: Icon(
        Icons.send,
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }

  Widget renderReplyView(BuildContext context, Message repliedToMessage) {
    final size = MediaQuery.of(context).size;
    final roomId = widget.roomId;

    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, child) =>
                      replyBuilder(roomId, repliedToMessage),
                ),
                _ReplyContentWidget(
                  roomId: widget.roomId,
                  msg: repliedToMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget renderEditView(BuildContext context, Message editMessage) {
    final size = MediaQuery.of(context).size;
    return renderChatInputArea(
      context,
      FrostEffect(
        widgetWidth: size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(builder: editMessageBuilder),
                _EditMessageContentWidget(
                  roomId: widget.roomId,
                  msg: editMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleFileUpload(
    List<File> files,
    AttachmentType attachmentType,
  ) async {
    final client = ref.read(alwaysClientProvider);
    final inputState = ref.read(chatInputProvider);
    final lang = L10n.of(context);
    final stream = await ref.read(
      timelineStreamProvider(widget.roomId).future,
    );

    try {
      for (File file in files) {
        String? mimeType = lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        final fileLen = file.lengthSync();
        if (mimeType.startsWith('image/') &&
            attachmentType == AttachmentType.image) {
          final bytes = file.readAsBytesSync();
          final image = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(fileLen)
              .width(image.width)
              .height(image.height);
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              imageDraft,
            );
          } else {
            await stream.sendMessage(imageDraft);
          }
        } else if (mimeType.startsWith('audio/') &&
            attachmentType == AttachmentType.audio) {
          final audioDraft =
              client.audioDraft(file.path, mimeType).size(file.lengthSync());
          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              audioDraft,
            );
          } else {
            await stream.sendMessage(audioDraft);
          }
        } else if (mimeType.startsWith('video/') &&
            attachmentType == AttachmentType.video) {
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(file.lengthSync());

          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              videoDraft,
            );
          } else {
            await stream.sendMessage(videoDraft);
          }
        } else {
          final fileDraft =
              client.fileDraft(file.path, mimeType).size(file.lengthSync());

          if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
            await stream.replyMessage(
              inputState.selectedMessage!.id,
              fileDraft,
            );
          } else {
            await stream.sendMessage(fileDraft);
          }
        }
      }
    } catch (e, s) {
      _log.severe('error occurred', e, s);
    }

    ref.read(chatInputProvider.notifier).unsetSelectedMessage();
  }

  Widget replyBuilder(String roomId, Message repliedToMessage) {
    final authorId = repliedToMessage.author.id;
    final memberAvatar =
        ref.watch(memberAvatarInfoProvider((userId: authorId, roomId: roomId)));
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Icons.reply_rounded,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        ActerAvatar(
          options: AvatarOptions.DM(
            memberAvatar,
            size: 12,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          L10n.of(context).replyTo(toBeginningOfSentenceCase(authorId)),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            inputNotifier.unsetSelectedMessage();
            // frame delay to keep focus connected with keyboard.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatFocus.requestFocus();
            });
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Widget editMessageBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final inputNotifier = ref.watch(chatInputProvider.notifier);
    return Row(
      children: [
        const SizedBox(width: 1),
        const Icon(
          Atlas.pencil_edit_thin,
          size: 12,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          L10n.of(context).editMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final convo = await ref.read(chatProvider(widget.roomId).future);
            await convo?.saveMsgDraft('', null, 'new', null);
            textController.clear();
            inputNotifier.unsetSelectedMessage();
            // frame delay to keep focus connected with keyboard..
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatFocus.requestFocus();
            });
          },
          child: const Icon(Atlas.xmark_circle),
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    if (textController.text.isEmpty) return;
    final lang = L10n.of(context);
    ref.read(chatInputProvider.notifier).startSending();
    try {
      // end the typing notification
      if (widget.onTyping != null) {
        widget.onTyping!(false);
      }

      final mentions = ref.read(chatInputProvider).mentions;
      String markdownText = textController.text;
      final userMentions = [];
      mentions.forEach((key, value) {
        userMentions.add(value);
        markdownText = markdownText.replaceAll(
          '@$key',
          '[@$key](https://matrix.to/#/$value)',
        );
      });

      // make the actual draft
      final client = ref.read(alwaysClientProvider);
      MsgDraft draft = client.textMarkdownDraft(markdownText);

      for (final userId in userMentions) {
        draft = draft.addMention(userId);
      }

      // actually send it out
      final inputState = ref.read(chatInputProvider);
      final stream = await ref.read(
        timelineStreamProvider(widget.roomId).future,
      );

      if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
        await stream.replyMessage(inputState.selectedMessage!.id, draft);
      } else if (inputState.selectedMessageState == SelectedMessageState.edit) {
        await stream.editMessage(inputState.selectedMessage!.id, draft);
      } else {
        await stream.sendMessage(draft);
      }

      ref.read(chatInputProvider.notifier).messageSent();

      textController.clear();
    } catch (e, s) {
      _log.severe('Sending chat message failed', e, s);
      EasyLoading.showError(
        lang.failedToSend(e),
        duration: const Duration(seconds: 3),
      );
      ref.read(chatInputProvider.notifier).sendingFailed();
    }
    if (!chatFocus.hasFocus) {
      chatFocus.requestFocus();
    }
  }
}

class _TextInputWidget extends ConsumerStatefulWidget {
  final String roomId;
  final ActerTriggerAutoCompleteTextController controller;
  final FocusNode chatFocus;
  final Function() onSendButtonPressed;
  final bool isEncrypted;
  final void Function(bool)? onTyping;

  const _TextInputWidget({
    required this.roomId,
    required this.controller,
    required this.chatFocus,
    required this.onSendButtonPressed,
    this.onTyping,
    this.isEncrypted = false,
  });

  @override
  ConsumerState<_TextInputWidget> createState() =>
      _TextInputWidgetConsumerState();
}

class _TextInputWidgetConsumerState extends ConsumerState<_TextInputWidget> {
  Timer? _debounceTimer;
  @override
  void initState() {
    super.initState();
    ref.listenManual(chatInputProvider, (prev, next) async {
      if (next.selectedMessageState == SelectedMessageState.edit &&
          (prev?.selectedMessageState != next.selectedMessageState ||
              next.selectedMessage != prev?.selectedMessage)) {
        // a new message has been selected to be edited or switched from reply
        // to edit, force refresh the inner text controller to reflect that
        if (next.selectedMessage != null) {
          widget.controller.text = parseEditMsg(next.selectedMessage!);
          // save edit UI state also by pointing reference event id.
          await saveDraft(widget.controller.text, next.selectedMessage!.id);
          // frame delay to keep focus connected with keyboard.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.chatFocus.requestFocus();
          });
        }
      } else if (next.selectedMessageState == SelectedMessageState.replyTo &&
          (next.selectedMessage != prev?.selectedMessage ||
              prev?.selectedMessageState != next.selectedMessageState)) {
        // save reply UI state also by pointing reference event id.
        await saveDraft(widget.controller.text, next.selectedMessage!.id);
        // frame delay to keep focus connected with keyboard..
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.chatFocus.requestFocus();
        });
      }
    });
  }

  void onTextTap(bool emojiPickerVisible, WidgetRef ref) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);

    ///Hide emoji picker before input field get focus if
    ///Platform is mobile & Emoji picker is visible
    if (!isDesktop && emojiPickerVisible) {
      chatInputNotifier.emojiPickerVisible(false);
    }
  }

  void onSuffixTap(
    bool emojiPickerVisible,
    BuildContext context,
    WidgetRef ref,
  ) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    if (!emojiPickerVisible) {
      //Hide soft keyboard and then show Emoji Picker
      chatInputNotifier.emojiPickerVisible(true);
    } else {
      //Hide Emoji Picker
      chatInputNotifier.emojiPickerVisible(false);
    }
  }

  // adds new line
  void _insertNewLine() {
    final TextSelection selection = widget.controller.selection;
    if (selection.isValid) {
      final String text = widget.controller.text;
      final int start = selection.start;
      final newText = text.replaceRange(start, selection.end, '\n');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + 1),
      );
    }
  }

  // save composer draft object handler
  Future<void> saveDraft(String text, String? eventId) async {
    // get the convo object to initiate draft
    final chat = await ref.read(chatProvider(widget.roomId).future);
    bool res = false;
    if (chat != null) {
      if (eventId != null) {
        final selectedMessageState =
            ref.read(chatInputProvider).selectedMessageState;
        if (selectedMessageState == SelectedMessageState.edit) {
          res = await chat.saveMsgDraft(text, null, 'edit', eventId);
        } else if (selectedMessageState == SelectedMessageState.replyTo) {
          res = await chat.saveMsgDraft(text, null, 'reply', eventId);
        }
      } else {
        res = await chat.saveMsgDraft(text, null, 'new', null);
      }

      _log.info('compose message state stored for room? $res|${widget.roomId}');
    }
  }

  // chat text field onChanged callback
  void _onTextChanged(String text) {
    // send typing notice
    if (widget.onTyping != null) {
      widget.onTyping!(text.isNotEmpty);
    }

    // Debounce the save operation to avoid excessive writes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // save composing draft
      saveDraft(text, ref.read(chatInputProvider).selectedMessage?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          widget.onSendButtonPressed();
        },
        LogicalKeySet(LogicalKeyboardKey.enter, LogicalKeyboardKey.shift): () {
          _insertNewLine();
        },
      },
      child: MultiTriggerAutocomplete(
        optionsAlignment: OptionsAlignment.top,
        textEditingController: widget.controller,
        focusNode: widget.chatFocus,
        autocompleteTriggers: [
          AutocompleteTrigger(
            trigger: '@',
            optionsViewBuilder: (context, autocompleteQuery, ctrl) {
              return MentionProfileBuilder(
                context: context,
                roomQuery: (
                  query: autocompleteQuery.query,
                  roomId: widget.roomId
                ),
              );
            },
          ),
        ],
        fieldViewBuilder: (context, ctrl, focusNode) =>
            _innerTextField(context, focusNode, ctrl),
      ),
    );
  }

  Widget _innerTextField(
    BuildContext context,
    FocusNode chatFocus,
    TextEditingController ctrl,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.2,
      ),
      child: TextField(
        maxLines: 5,
        minLines: 1,
        onTap: () => onTextTap(
          ref.read(chatInputProvider).emojiPickerVisible,
          ref,
        ),
        controller: widget.controller,
        focusNode: chatFocus,
        enabled: ref.watch(_allowEdit(widget.roomId)),
        onChanged: _onTextChanged,
        onSubmitted: (_) => widget.onSendButtonPressed(),
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(15),
          isCollapsed: true,
          prefixIcon: widget.isEncrypted
              ? Icon(
                  Icons.shield,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                )
              : null,
          suffixIcon: InkWell(
            onTap: () => onSuffixTap(
              ref.read(chatInputProvider).emojiPickerVisible,
              context,
              ref,
            ),
            child: const Icon(Icons.emoji_emotions),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              width: 0.5,
              style: BorderStyle.solid,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              width: 0.5,
              style: BorderStyle.solid,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              width: 0.5,
              style: BorderStyle.solid,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          hintText: widget.isEncrypted
              ? L10n.of(context).newEncryptedMessage
              : L10n.of(context).newMessage,
          hintStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          hintMaxLines: 1,
        ),
      ),
    );
  }
}

class _ReplyContentWidget extends StatelessWidget {
  final String roomId;
  final Message msg;

  const _ReplyContentWidget({
    required this.roomId,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          roomId: roomId,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    } else if (msg is FileMessage) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          msg.metadata?['content'],
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else if (msg is CustomMessage) {
      return CustomMessageBuilder(
        message: msg as CustomMessage,
        messageWidth: 100,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          L10n.of(context).replyPreviewUnavailable,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
  }
}

class _EditMessageContentWidget extends StatelessWidget {
  final String roomId;
  final Message msg;

  const _EditMessageContentWidget({
    required this.roomId,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      final imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          roomId: roomId,
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      final textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

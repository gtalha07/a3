import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/common/widgets/html_editor/models/mention_attributes.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:logging/logging.dart';

// send chat message action
Future<void> sendMessageAction({
  required EditorState textEditorState,
  required String roomId,
  required BuildContext context,
  required WidgetRef ref,
  void Function(bool)? onTyping,
  required Logger log,
}) async {
  final lang = L10n.of(context);
  final body = textEditorState.intoMarkdown();
  final html = textEditorState.intoHtml();

  if (!hasValidEditorContent(plainText: body, html: html)) {
    return;
  }

  final bodyProcessedText = textEditorState.mentionsParsedText(body, null);
  ref.read(chatInputProvider.notifier).startSending();
  try {
    // end the typing notification
    onTyping?.map((cb) => cb(false));

    // make the actual draft
    final client = await ref.read(alwaysClientProvider.future);
    late MsgDraft draft;
    if (html.isNotEmpty) {
      final htmlProcessedText = textEditorState.mentionsParsedText(body, html);
      draft = client.textHtmlDraft(htmlProcessedText.$1, bodyProcessedText.$1);
      if (htmlProcessedText.$2.isNotEmpty) {
        for (MentionAttributes m in htmlProcessedText.$2) {
          draft.addMention(m.mentionId);
        }
      }
    } else {
      draft = client.textMarkdownDraft(bodyProcessedText.$1);
      if (bodyProcessedText.$2.isNotEmpty) {
        for (MentionAttributes m in bodyProcessedText.$2) {
          draft.addMention(m.mentionId);
        }
      }
    }

    // actually send it out
    final chatEditorState = ref.read(chatEditorStateProvider);
    final stream = await ref.read(timelineStreamProvider(roomId).future);

    if (chatEditorState.isReplying) {
      final remoteId = chatEditorState.selectedMsgItem?.eventId();
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.replyMessage(remoteId, draft);
    } else if (chatEditorState.isEditing) {
      final remoteId = chatEditorState.selectedMsgItem?.eventId();
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.editMessage(remoteId, draft);
    } else {
      await stream.sendMessage(draft);
    }

    ref.read(chatInputProvider.notifier).messageSent();
    textEditorState.clear();

    // also clear composed state
    final convo = await ref.read(chatProvider(roomId).future);
    final notifier = ref.read(chatEditorStateProvider.notifier);
    notifier.unsetActions();
    if (convo != null) {
      await convo.saveMsgDraft(
        textEditorState.intoMarkdown(),
        null,
        'new',
        null,
      );
    }
  } catch (e, s) {
    log.severe('Sending chat message failed', e, s);
    EasyLoading.showError(
      lang.failedToSend(e),
      duration: const Duration(seconds: 3),
    );
    ref.read(chatInputProvider.notifier).sendingFailed();
  }
}

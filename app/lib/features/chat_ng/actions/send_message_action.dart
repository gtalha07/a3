import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  ref.read(chatInputProvider.notifier).startSending();

  try {
    // end the typing notification
    onTyping?.map((cb) => cb(false));

    // make the actual draft
    final client = ref.read(alwaysClientProvider);
    late MsgDraft draft;
    if (html.isNotEmpty) {
      draft = client.textHtmlDraft(html, body);
    } else {
      draft = client.textMarkdownDraft(body);
    }

    // actually send it out
    final inputState = ref.read(chatInputProvider);
    final stream = await ref.read(timelineStreamProvider(roomId).future);

    if (inputState.selectedMessageState == SelectedMessageState.replyTo) {
      final remoteId = inputState.selectedMessage?.remoteId;
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.replyMessage(remoteId, draft);
    } else if (inputState.selectedMessageState == SelectedMessageState.edit) {
      final remoteId = inputState.selectedMessage?.remoteId;
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.editMessage(remoteId, draft);
    } else {
      await stream.sendMessage(draft);
    }

    ref.read(chatInputProvider.notifier).messageSent();
    final transaction = textEditorState.transaction;
    final nodes = transaction.document.root.children;
    // delete all nodes of document (reset)
    transaction.document.delete([0], nodes.length);
    final delta = Delta()..insert('');
    // insert empty text node
    transaction.document.insert([0], [paragraphNode(delta: delta)]);
    await textEditorState.apply(transaction, withUpdateSelection: false);
    // FIXME: works for single line text, but doesn't get focus on multi-line (iOS)
    textEditorState.moveCursorForward(SelectionMoveRange.line);

    // also clear composed state
    final convo = await ref.read(chatProvider(roomId).future);
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

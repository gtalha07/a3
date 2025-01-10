import 'package:acter/common/widgets/html_editor/components/mention_menu.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

List<CharacterShortcutEvent> mentionShortcuts(
  BuildContext context,
  String roomId,
) {
  return [
    CharacterShortcutEvent(
      character: userMentionChar,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        mentionTrigger: userMentionChar,
        editorState: editorState,
        roomId: roomId,
      ),
      key: userMentionChar,
    ),
    CharacterShortcutEvent(
      character: roomMentionChar,
      handler: (editorState) => _handleMentionTrigger(
        context: context,
        mentionTrigger: roomMentionChar,
        editorState: editorState,
        roomId: roomId,
      ),
      key: roomMentionChar,
    ),
  ];
}

Future<bool> _handleMentionTrigger({
  required BuildContext context,
  required String mentionTrigger,
  required EditorState editorState,
  required String roomId,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }
  // dismiss menu
  if (MentionOverlayState.isShowing) {
    MentionOverlayState.dismiss();
    MentionOverlayState.currentMenu = null;
    return true;
  }

  // Insert the mention trigger character
  await editorState.insertTextAtPosition(
    mentionTrigger,
    position: selection.start,
  );

  // Show the menu
  if (context.mounted) {
    final menu = MentionMenu(
      context: context,
      editorState: editorState,
      roomId: roomId,
      mentionTrigger: mentionTrigger,
    );
    MentionOverlayState.currentMenu = menu;
    menu.show();
  }
  return true;
}

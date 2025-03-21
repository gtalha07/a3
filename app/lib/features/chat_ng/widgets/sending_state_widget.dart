import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/widgets/pulsating_icon.dart';
import 'package:acter/features/chat_ng/widgets/sending_error_dialog.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:flutter/material.dart';

class SentStateWidget extends StatelessWidget {
  const SentStateWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.check, color: Theme.of(context).colorScheme.primary);
}

class SendingStateWidget extends StatelessWidget {
  final EventSendState state;
  final bool showSentIconOnUnknown;

  const SendingStateWidget({
    super.key,
    required this.state,
    this.showSentIconOnUnknown = false,
  });

  @override
  Widget build(BuildContext context) => switch (state.state()) {
    'NotSentYet' => PulsatingIcon(
      icon: Icons.send,
      color: Theme.of(context).colorScheme.onSecondary,
    ),
    'SendingFailed' => _buildSendingFailed(context),
    'Sent' => SentStateWidget(),
    _ => showSentIconOnUnknown ? SentStateWidget() : const SizedBox.shrink(),
  };

  static Widget sent() => SentStateWidget();

  Widget _buildSendingFailed(BuildContext context) =>
      ActerInlineTextButton.icon(
        onPressed:
            () => SendingErrorDialog.show(context: context, state: state),
        icon: const Icon(Icons.error),
        label: Text(L10n.of(context).chatSendingFailed),
      );
}

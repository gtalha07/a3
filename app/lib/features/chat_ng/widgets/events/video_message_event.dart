import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/video_dialog.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

class VideoMessageEvent extends ConsumerWidget {
  final String roomId;
  final String messageId;
  final MsgContent content;
  final int? timestamp;

  const VideoMessageEvent({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.content,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatMessageInfo messageInfo = (messageId: messageId, roomId: roomId);
    final mediaState = ref.watch(mediaChatStateProvider(messageInfo));
    if (mediaState.mediaChatLoadingState.isLoading ||
        mediaState.isDownloading) {
      return loadingIndication(context);
    }
    final mediaFile = mediaState.mediaFile;
    if (mediaFile == null) {
      return videoPlaceholder(context, roomId, ref);
    } else {
      return videoUI(context, mediaFile, mediaState.videoThumbnailFile);
    }
  }

  Widget loadingIndication(BuildContext context) {
    return const SizedBox(
      width: 150,
      height: 150,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget videoPlaceholder(BuildContext context, String roomId, WidgetRef ref) {
    final msgSize = content.size();
    if (msgSize == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () async {
        final notifier = ref.read(
          mediaChatStateProvider((
            messageId: messageId,
            roomId: roomId,
          )).notifier,
        );
        await notifier.downloadMedia();
      },
      child: SizedBox(
        width: 200,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download, size: 28),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.video_library_rounded, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    formatBytes(msgSize.truncate()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (timestamp != null)
              Container(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                alignment: Alignment.bottomRight,
                child: MessageTimestampWidget(
                  timestamp: timestamp.expect('should not be null'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget videoUI(BuildContext context, File mediaFile, File? thumbFile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () {
          showAdaptiveDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: false,
            builder:
                (context) =>
                    VideoDialog(title: content.body(), videoFile: mediaFile),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (thumbFile != null) videoThumbFileView(context, thumbFile),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: 50.0,
                    semanticLabel: L10n.of(context).play,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget videoThumbFileView(BuildContext context, File thumbFile) {
    return Stack(
      children: [
        Image.file(
          thumbFile,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, url, error) {
            return Text(L10n.of(context).couldNotLoadImage(error.toString()));
          },
          fit: BoxFit.cover,
        ),
        if (timestamp != null)
          Positioned(
            bottom: 0,
            right: 8,
            child: MessageTimestampWidget(
              timestamp: timestamp.expect('should not be null'),
            ),
          ),
      ],
    );
  }
}

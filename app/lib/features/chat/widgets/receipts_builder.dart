import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Convo;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ReceiptsBuilder extends ConsumerWidget {
  final Convo convo;
  final types.Message message;
  const ReceiptsBuilder({
    super.key,
    required this.convo,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = message.metadata?['receipts'];
    final sendState = message.metadata?['eventState'];
    if (receipts != null && receipts.isNotEmpty) {
      return _UserReceiptsWidget(
        seenList: (receipts as Map<String, int>).keys.toList(),
      );
    } else {
      if (sendState != null) {
        switch (sendState) {
          case 'NotSentYet':
            return const SizedBox(
              height: 8,
              width: 8,
              child: CircularProgressIndicator(),
            );
          case 'SendingFailed':
            return GestureDetector(
              onTap: () => _handleRetry(),
              child: Row(
                children: <Widget>[
                  Text(
                    'Retry',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                        ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Atlas.warning_thin,
                    color: Theme.of(context).colorScheme.error,
                    size: 8,
                  ),
                ],
              ),
            );
          case 'Sent':
            return const Icon(Atlas.check_circle_thin, size: 8);
        }
      }
      return const SizedBox.shrink();
    }
  }

  Future<void> _handleRetry() async {
    // FIXME: how to handle retry here
  }
}

class _UserReceiptsWidget extends ConsumerWidget {
  final List<String> seenList;
  const _UserReceiptsWidget({required this.seenList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = seenList.length > 5 ? 5 : seenList.length;
    final subList =
        limit == seenList.length ? seenList : seenList.sublist(0, limit);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: QudsPopupButton(
        items: showDetails(),
        child: Wrap(
          spacing: -16,
          children: limit != seenList.length
              ? [
                  for (var userId in subList)
                    Consumer(
                      builder: (context, ref, child) {
                        final memberProfile =
                            ref.watch(memberProfileByIdProvider(userId));
                        return memberProfile.when(
                          data: (profile) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName: profile.displayName ?? userId,
                                  avatar: profile.getAvatarImage(),
                                ),
                                size: 8,
                              ),
                            );
                          },
                          error: (e, st) {
                            debugPrint('ERROR loading avatar due to $e');
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName: userId,
                                ),
                                size: 8,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 8,
                            width: 8,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  CircleAvatar(
                    radius: 8,
                    child: Text(
                      '+${seenList.length - subList.length}',
                      textScaleFactor: 0.4,
                    ),
                  ),
                ]
              : List.generate(
                  seenList.length,
                  (idx) => Consumer(
                    builder: (context, ref, child) {
                      final memberProfile =
                          ref.watch(memberProfileByIdProvider(seenList[idx]));
                      final userId = seenList[idx];
                      return memberProfile.when(
                        data: (profile) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              mode: DisplayMode.DM,
                              avatarInfo: AvatarInfo(
                                uniqueId: userId,
                                displayName: profile.displayName ?? userId,
                                avatar: profile.getAvatarImage(),
                              ),
                              size: 8,
                            ),
                          );
                        },
                        error: (e, st) {
                          debugPrint('ERROR loading avatar due to $e');
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ActerAvatar(
                              mode: DisplayMode.DM,
                              avatarInfo: AvatarInfo(
                                uniqueId: userId,
                                displayName: userId,
                              ),
                              size: 8,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 8,
                          width: 8,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  List<QudsPopupMenuBase> showDetails() {
    return [
      QudsPopupMenuWidget(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Seen By',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: seenList.length,
                itemBuilder: (context, index) {
                  final userId = seenList[index];
                  return Consumer(
                    builder: (context, ref, child) {
                      final member =
                          ref.watch(memberProfileByIdProvider(userId));
                      return ListTile(
                        leading: member.when(
                          data: (profile) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: seenList[index],
                                  displayName: profile.displayName ?? userId,
                                  avatar: profile.getAvatarImage(),
                                ),
                                size: 8,
                              ),
                            );
                          },
                          error: (e, st) {
                            debugPrint('ERROR loading avatar due to $e');
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActerAvatar(
                                mode: DisplayMode.DM,
                                avatarInfo: AvatarInfo(
                                  uniqueId: userId,
                                  displayName: userId,
                                ),
                                size: 8,
                              ),
                            );
                          },
                          loading: () => const SizedBox(
                            height: 8,
                            width: 8,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        title: Text(
                          member.hasValue
                              ? member.requireValue.displayName!
                              : userId,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: Text(
                          userId,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.neutral5,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

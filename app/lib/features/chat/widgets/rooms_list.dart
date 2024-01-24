import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/convo_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

final bucketGlobal = PageStorageBucket();
// interface providers
final _searchToggleProvider = StateProvider.autoDispose<bool>((ref) => false);

class RoomsListWidget extends ConsumerWidget {
  static const roomListMenuKey = Key('room-list');

  const RoomsListWidget({
    super.key = roomListMenuKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final showSearch = ref.watch(_searchToggleProvider);
    final searchNotifier = ref.watch(_searchToggleProvider.notifier);
    final inSideBar = ref.watch(inSideBarProvider);
    return PageStorage(
      bucket: bucketGlobal,
      child: CustomScrollView(
        key: const PageStorageKey<String>('convo-list'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverAppBar(
                automaticallyImplyLeading: false,
                floating: true,
                elevation: 0,
                leading: showSearch
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: TextFormField(
                          autofocus: true,
                          onChanged: (value) => ref
                              .read(chatSearchValueProvider.notifier)
                              .update((state) => value),
                          cursorColor:
                              Theme.of(context).colorScheme.tertiary2,
                          decoration: InputDecoration(
                            hintStyle: const TextStyle(color: Colors.white),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                searchNotifier.update((state) => false);
                                ref
                                    .read(
                                      chatSearchValueProvider.notifier,
                                    )
                                    .state = null;
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 12,
                              bottom: 2,
                              top: 2,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          AppLocalizations.of(context)!.chat,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                leadingWidth: double.infinity,
                actions: showSearch
                    ? []
                    : [
                        IconButton(
                          onPressed: () {
                            searchNotifier.update((state) => !state);
                          },
                          padding: const EdgeInsets.only(right: 10, left: 5),
                          icon: const Icon(Atlas.magnifying_glass),
                        ),
                        IconButton(
                          onPressed: () async => context.pushNamed(
                            Routes.createChat.name,
                          ),
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          icon: const Icon(
                            Atlas.plus_circle_thin,
                          ),
                        ),
                      ],
              );
            },
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 1,
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          SliverToBoxAdapter(
            child: client.isGuest()
                ? empty
                : ConvosList(
                    onSelected: (String roomId) {
                      inSideBar
                          ? context.goNamed(
                              Routes.chatroom.name,
                              pathParameters: {'roomId': roomId},
                            )
                          : context.pushNamed(
                              Routes.chatroom.name,
                              pathParameters: {'roomId': roomId},
                            );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  SvgPicture get empty {
    return SvgPicture.asset('assets/images/empty_messages.svg');
  }
}

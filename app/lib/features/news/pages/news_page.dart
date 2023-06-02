import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final account = ref.watch(accountProfileProvider);
    final bool isDesktop =
        desktopPlatforms.contains(Theme.of(context).platform);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MediaQuery.of(context).size.width < 600
            ? !client.isGuest()
                ? account.when(
                    data: (data) => Container(
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.neutral6,
                        ),
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.only(left: 10, top: 8),
                      child: ActerAvatar(
                        mode: DisplayMode.User,
                        uniqueId: client.userId().toString(),
                        avatar: data.profile.getAvatarImage(),
                        size: 36,
                      ),
                    ),
                    error: (error, stackTrace) =>
                        Text('Failed to load due to $error'),
                    loading: () => const CircularProgressIndicator(),
                  )
                : GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      alignment: Alignment.topLeft,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.neutral6,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: ActerAvatar(
                        mode: DisplayMode.User,
                        uniqueId: client.userId().toString(),
                        size: 36,
                      ),
                    ),
                  )
            : const SizedBox.shrink(),
        centerTitle: true,
        actions: <Widget>[
          Visibility(
            visible: !isDesktop,
            child: IconButton(
              /// [GoRouter] use context.push() for preserving states
              /// of previous route and context.go() for vice versa.
              onPressed: () => context.push('/updates/edit'),
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: const NewsWidget(),
    );
  }
}

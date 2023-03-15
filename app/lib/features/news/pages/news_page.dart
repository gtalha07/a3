import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/features/news/controllers/news_controller.dart';
import 'package:acter/features/news/widgets/news_item.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/constants.dart' show Keys;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsList = ref.watch(newsListProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MediaQuery.of(context).size.width < 600
            ? IconButton(
                key: Keys.sidebarBtn,
                icon: const UserAvatarWidget(isExtendedRail: false),
                onPressed: () => confirmationDialog(context, ref),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              )
            : const SizedBox.shrink(),
        centerTitle: true,
        title: const ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            Text(
              'All',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: <Shadow>[
                  Shadow(
                    blurRadius: 1.0,
                    color: Colors.black,
                  ),
                ],
                fontWeight: FontWeight.w100,
              ),
            ),
            Text(
              'News',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: <Shadow>[
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.white,
                  ),
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Stories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: <Shadow>[
                  Shadow(
                    blurRadius: 1.0,
                    color: Colors.black,
                  ),
                ],
                fontWeight: FontWeight.w100,
              ),
            ),
          ],
        ),
      ),
      body: newsList.when(
        data: (data) {
          return PageView.builder(
            itemCount: data.length,
            onPageChanged: (int page) {},
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) => InkWell(
              onDoubleTap: () {
                LikeAnimation.run(index);
              },
              child: NewsItem(
                client: ref.read(homeStateProvider)!,
                news: data[index],
                index: index,
              ),
            ),
          );
        },
        error: (error, stackTrace) =>
            const Center(child: Text('Couldn\'t fetch news')),
        loading: () => const Center(
          child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(
              color: AppCommonTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/create_or_join_space_tutorials.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MySpacesSection extends ConsumerWidget {
  final int? limit;

  const MySpacesSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);

    int spacesLimit =
        (limit != null && spaces.length > limit!) ? limit! : spaces.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: DashboardKeys.widgetMySpacesHeader,
          onTap: () => context.pushNamed(Routes.spaces.name),
          child: Text(
            L10n.of(context).mySpaces,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        spaces.isEmpty
            ? const _NoSpacesWidget()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: spacesLimit,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SpaceCard(space: spaces[index]);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: spacesLimit != spaces.length
                        ? OutlinedButton(
                            onPressed: () {
                              context.pushNamed(Routes.spaces.name);
                            },
                            child: Text(
                              L10n.of(context).seeAllMySpaces(spaces.length),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    context.pushNamed(Routes.createSpace.name),
                                child: Text(L10n.of(context).createSpace),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () =>
                                    context.pushNamed(Routes.joinSpace.name),
                                child: Text(L10n.of(context).joinSpace),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _NoSpacesWidget extends ConsumerStatefulWidget {
  const _NoSpacesWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NoSpacesWidgetState();
}

class _NoSpacesWidgetState extends ConsumerState<_NoSpacesWidget> {
  @override
  void initState() {
    super.initState();
    if (!isDesktop) createOrJoinSpaceTutorials(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          L10n.of(context).youAreCurrentlyNotConnectedToAnySpaces,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).create,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(text: L10n.of(context).or),
              TextSpan(
                text: L10n.of(context).join,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: ' ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextSpan(
                text: L10n.of(context).spaceShortDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          softWrap: true,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: ElevatedButton(
            key: createNewSpaceKey,
            onPressed: () => context.pushNamed(Routes.createSpace.name),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.neutral6,
              foregroundColor: Theme.of(context).colorScheme.neutral,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide.none,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(L10n.of(context).createNewSpace),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: ElevatedButton(
            key: joinExistingSpaceKey,
            onPressed: () {
              context.pushNamed(Routes.joinSpace.name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.neutral6,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.neutral6,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(L10n.of(context).joinExistingSpace),
          ),
        ),
      ],
    );
  }
}

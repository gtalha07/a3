import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/model/util.dart';
import 'package:acter/features/search/providers/pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinsBuilder extends ConsumerWidget {
  final NavigateTo navigateTo;

  const PinsBuilder({
    super.key,
    required this.navigateTo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundPins = ref.watch(pinsFoundProvider);
    return foundPins.when(
      loading: () => Text(L10n.of(context).loading),
      error: (e, st) => Text(L10n.of(context).error(e)),
      data: (data) {
        final Widget body;
        if (data.isEmpty) {
          body = Text(L10n.of(context).noMatchingPinsFound);
        } else {
          final List<Widget> children = data
              .map(
                (e) => InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        e.icon,
                        const SizedBox(width: 5),
                        Text(e.name),
                      ],
                    ),
                  ),
                  onTap: () async => await navigateTo(
                    Routes.pin,
                    pathParameters: {'pinId': e.navigationTargetId},
                    push: true,
                  ),
                ),
              )
              .toList();
          body = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: children),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Text(L10n.of(context).pins),
              const SizedBox(height: 15),
              body,
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

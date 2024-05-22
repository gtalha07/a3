import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AboutCard extends ConsumerWidget {
  final String spaceId;

  const AboutCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceProvider(spaceId));
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  L10n.of(context).about,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
              ],
            ),
            space.when(
              data: (space) {
                final topic = space.topic();
                return Text(
                  topic ?? L10n.of(context).noTopicFound,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              error: (error, stack) => Text(
                L10n.of(context).loadingFailed(error),
              ),
              loading: () => Skeletonizer(
                child: Text(L10n.of(context).loading),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

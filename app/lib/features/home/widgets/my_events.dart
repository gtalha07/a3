import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::home::my_events');

class MyEventsSection extends ConsumerWidget {
  final int? limit;
  final EventFilters eventFilters;

  const MyEventsSection({
    super.key,
    this.limit,
    this.eventFilters = EventFilters.upcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    //Get my events data
    final calEventsLoader = switch (eventFilters) {
      EventFilters.ongoing => ref.watch(myOngoingEventListProvider(null)),
      _ => ref.watch(myUpcomingEventListProvider(null)),
    };
    final sectionTitle = switch (eventFilters) {
      EventFilters.ongoing => lang.happeningNow,
      _ => lang.myUpcomingEvents,
    };

    return calEventsLoader.when(
      data: (calEvents) {
        if (calEvents.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(context, sectionTitle),
            eventListUI(context, calEvents),
          ],
        );
      },
      error: (e, s) {
        _log.severe('Failed to load cal events', e, s);
        return Text(lang.loadingEventsFailed(e));
      },
      loading: () => const EventListSkeleton(),
    );
  }

  Widget sectionHeader(BuildContext context, String sectionTitle) {
    return Row(
      children: [
        Text(
          sectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        ActerInlineTextButton(
          onPressed: () => context.pushNamed(Routes.calendarEvents.name),
          child: Text(L10n.of(context).seeAll),
        ),
      ],
    );
  }

  Widget eventListUI(BuildContext context, List<CalendarEvent> events) {
    final count = limit.map((val) => min(val, events.length)) ?? events.length;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => EventItem(
        isShowSpaceName: true,
        margin: const EdgeInsets.only(bottom: 14),
        event: events[index],
      ),
    );
  }
}

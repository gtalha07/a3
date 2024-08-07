import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class EventsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const EventsSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsList = ref.watch(
      eventListSearchFilterProvider(
        (spaceId: spaceId, searchText: ''),
      ),
    );
    return eventsList.when(
      data: (events) => buildEventsSectionUI(context, events),
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildEventsSectionUI(
    BuildContext context,
    List<CalendarEvent> events,
  ) {
    int eventsLimit = (events.length > limit) ? limit : events.length;
    bool isShowSeeAllButton = events.length > eventsLimit;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).events,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceEvents.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        eventsListUI(events, eventsLimit),
      ],
    );
  }

  Widget eventsListUI(List<CalendarEvent> events, int eventsLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: eventsLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return EventItem(event: events[index]);
      },
    );
  }
}

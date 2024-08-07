import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:dart_date/dart_date.dart';

Future<List<ffi.CalendarEvent>> sortEventListAscTime(
  List<ffi.CalendarEvent> eventsList,
) async {
  eventsList.sort(
    (a, b) => a.utcStart().timestamp().compareTo(b.utcStart().timestamp()),
  );
  return eventsList;
}

Future<List<ffi.CalendarEvent>> sortEventListDscTime(
  List<ffi.CalendarEvent> eventsList,
) async {
  eventsList.sort(
    (a, b) => b.utcStart().timestamp().compareTo(a.utcStart().timestamp()),
  );
  return eventsList;
}

EventFilters getEventType(ffi.CalendarEvent event) {
  DateTime eventStartDateTime = toDartDatetime(event.utcStart());
  DateTime eventEndDateTime = toDartDatetime(event.utcEnd());
  DateTime currentDateTime = DateTime.now().toUTC;

  //Check for event type
  if (eventStartDateTime.isBefore(currentDateTime) &&
      eventEndDateTime.isAfter(currentDateTime)) {
    return EventFilters.ongoing;
  } else if (eventStartDateTime.isAfter(currentDateTime)) {
    return EventFilters.upcoming;
  } else if (eventEndDateTime.isBefore(currentDateTime)) {
    return EventFilters.past;
  }
  return EventFilters.all;
}

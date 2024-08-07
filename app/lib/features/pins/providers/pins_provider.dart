import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/providers/notifiers/edit_state_notifier.dart';
import 'package:acter/features/pins/providers/notifiers/pins_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

//SpaceId == null : GET LIST OF ALL PINs
//SpaceId != null : GET LIST OF SPACE PINs
final pinListProvider =
    AsyncNotifierProvider.family<AsyncPinListNotifier, List<ActerPin>, String?>(
  () => AsyncPinListNotifier(),
);

//Search any pins
typedef AllPinsSearchParams = ({String? spaceId, String searchText});

final pinListSearchProvider = FutureProvider.autoDispose
    .family<List<ActerPin>, AllPinsSearchParams>((ref, params) async {
  final pinList = await ref.watch(pinListProvider(params.spaceId).future);
  List<ActerPin> filteredPinList = [];
  for (final pin in pinList) {
    if (pin.title().toLowerCase().contains(params.searchText.toLowerCase())) {
      filteredPinList.add(pin);
    }
  }
  return filteredPinList;
});

//Get single pin details
final pinProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncPinNotifier, ActerPin, String>(
  () => AsyncPinNotifier(),
);

//Update single pin details
final pinEditProvider = StateNotifierProvider.family
    .autoDispose<PinEditNotifier, PinEditState, ActerPin>(
  (ref, pin) => PinEditNotifier(pin: pin, ref: ref),
);

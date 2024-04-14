import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/public_room_search/models/publiic_search_result_state.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class PublicSearchNotifier extends StateNotifier<PublicSearchResultState>
    with
        PagedNotifierMixin<Next?, PublicSearchResultItem,
            PublicSearchResultState> {
  final Ref ref;

  PublicSearchNotifier(this.ref)
      : super(PublicSearchResultState(filter: ref.read(searchFilterProvider))) {
    setup();
  }

  void setup() {
    ref.read(searchFilterProvider.notifier).addListener((state) {
      readData();
    });
  }

  void readData() async {
    try {
      await ref.debounce(const Duration(milliseconds: 300));
      refresh();
    } catch (e) {
      // we do not care.
    }
  }

  void refresh() {
    const nextPageKey = Next(isStart: true);
    final currentFilters = ref.read(searchFilterProvider);
    state = state.copyWith(
      records: [],
      nextPageKey: nextPageKey,
      filter: currentFilters,
    );
    load(nextPageKey, 30);
  }

  @override
  Future<List<PublicSearchResultItem>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    final client = ref.read(alwaysClientProvider);
    final searchValue = state.filter.searchTerm;
    final server = state.filter.server;
    try {
      final res = await client.publicSpaces(searchValue, server, pageReq);
      final entries = res.chunks();
      final next = res.nextBatch();
      Next? finalPageKey;
      if (next != null) {
        // we are not at the end
        finalPageKey = Next(next: next);
      }
      state = state.copyWith(
        records: page.isStart
            ? [...entries]
            : [...(state.records ?? []), ...entries],
        nextPageKey: finalPageKey,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }

    return null;
  }
}

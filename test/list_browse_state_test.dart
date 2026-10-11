import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/models/list_browse_state.dart';

void main() {
  test('query/filter combine; sort ties remain stable and source order is unchanged', () {
    final source = [(1, 'Beta', true), (2, 'alpha', false), (3, 'Alpha', true)];
    final state = ListBrowseState()..sort = 'title';
    List<(int, String, bool)> results() => state.matching(
      source,
      searchText: (r) => r.$2,
      title: (r) => r.$2,
      matchesFilter: (r, f) => r.$3,
      current: (r) => r.$3,
    );
    expect(results().map((r) => r.$1), [2, 3, 1]);
    state.sort = 'title-desc';
    expect(results().map((r) => r.$1), [1, 2, 3]);
    state.sort = 'current';
    expect(results().map((r) => r.$1), [1, 3, 2]);
    state.query = ' ALPHA ';
    state.filter = 'current';
    expect(results().map((r) => r.$1), [3]);
    expect(state.canReorder, isFalse);
    state.reset();
    expect(results(), source);
    expect(state.canReorder, isTrue);
  });
  test('page slices cap rendered items, clamp after shrinking and handle no matches', () {
    final state = ListBrowseState()..page = 2;
    final rows = List.generate(45, (i) => i);
    expect(state.slice(rows), [40, 41, 42, 43, 44]);
    expect(state.slice(rows.take(20).toList()).length, 20);
    expect(state.page, 0);
    state.page = 100;
    expect(state.slice(<int>[]), isEmpty);
    expect(state.page, 0);
  });
}

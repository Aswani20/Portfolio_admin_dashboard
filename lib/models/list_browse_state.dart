/// Session-only browsing preferences. Never serialized into portfolio content.
class ListBrowseState {
  String query = '';
  String filter = '';
  String sort = 'order';
  int page = 0;
  bool get canReorder =>
      query.trim().isEmpty && filter.isEmpty && sort == 'order';
  bool get isDefault =>
      query.isEmpty && filter.isEmpty && sort == 'order' && page == 0;
  void reset() {
    query = '';
    filter = '';
    sort = 'order';
    page = 0;
  }

  List<T> matching<T>(
    List<T> records, {
    required String Function(T) searchText,
    required String Function(T) title,
    bool Function(T, String)? matchesFilter,
    String Function(T)? secondary,
    bool Function(T)? current,
  }) {
    final queryText = query.trim().toLowerCase();
    final indexed = records.indexed
        .where(
          (item) =>
              searchText(item.$2).toLowerCase().contains(queryText) &&
              (filter.isEmpty ||
                  (matchesFilter?.call(item.$2, filter) ?? false)),
        )
        .toList();
    if (sort != 'order') {
      indexed.sort((a, b) {
        var compared = sort == 'current' && current != null
            ? (current(b.$2) ? 1 : 0).compareTo(current(a.$2) ? 1 : 0)
            : (sort == 'secondary' && secondary != null
                      ? secondary(a.$2)
                      : title(a.$2))
                  .toLowerCase()
                  .compareTo(
                    (sort == 'secondary' && secondary != null
                            ? secondary(b.$2)
                            : title(b.$2))
                        .toLowerCase(),
                  );
        if (sort == 'title-desc') compared = -compared;
        return compared == 0 ? a.$1.compareTo(b.$1) : compared;
      });
    }
    return indexed.map((item) => item.$2).toList();
  }

  List<T> slice<T>(List<T> matching, {int size = 20}) {
    final last = matching.isEmpty ? 0 : (matching.length - 1) ~/ size;
    page = page.clamp(0, last);
    return matching.skip(page * size).take(size).toList();
  }
}

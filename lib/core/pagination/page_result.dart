/// One page of a server-side paginated list.
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.total,
    required this.offset,
  });

  const PageResult.empty() : items = const [], total = 0, offset = 0;

  final List<T> items;

  /// Total rows matching the query on the server (not just this page).
  final int total;

  /// Offset of the first item of this page.
  final int offset;

  int get nextOffset => offset + items.length;
  bool get hasMore => nextOffset < total && items.isNotEmpty;
}

/// Default page size used by list screens.
const int defaultPageSize = 25;

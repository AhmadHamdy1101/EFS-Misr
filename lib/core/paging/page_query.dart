/// One page of a list request plus the search and filters that apply to it.
/// Data sources turn it into `.range(from, to)` and server-side filters.
class PageQuery {
  const PageQuery({
    this.page = 0,
    this.pageSize = defaultPageSize,
    this.search = '',
    this.areaId,
    this.branchId,
  });

  static const defaultPageSize = 30;

  final int page;
  final int pageSize;
  final String search;
  final int? areaId;
  final int? branchId;

  int get from => page * pageSize;
  int get to => from + pageSize - 1;
  bool get hasSearch => search.isNotEmpty;

  PageQuery nextPage() => PageQuery(
    page: page + 1,
    pageSize: pageSize,
    search: search,
    areaId: areaId,
    branchId: branchId,
  );
}

/// Builds the body of a PostgREST `or(...)` filter matching [search] against
/// each of [columns] with `ilike`. The value is double-quoted so commas,
/// parentheses and dots typed by the user can't change the filter syntax.
String ilikeAny(List<String> columns, String search) {
  final escaped = search.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return columns.map((column) => '$column.ilike."%$escaped%"').join(',');
}

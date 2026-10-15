import 'dart:async';

import 'package:dartz/dartz.dart';

import '../Errors/failure.dart';
import 'page_query.dart';

/// Page bookkeeping shared by the list cubits: the loaded rows, which page
/// comes next, whether more rows exist, and which request is current so a
/// response for an older search or filter is dropped instead of shown.
class PageLoader<T> {
  PageLoader(
    this._fetch, {
    required this.idOf,
    this.pageSize = PageQuery.defaultPageSize,
  });

  final Future<Either<Failure, List<T>>> Function(PageQuery query) _fetch;
  final Object Function(T item) idOf;
  final int pageSize;

  final List<T> items = [];
  PageQuery _next = const PageQuery();
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _generation = 0;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get canLoadMore => _hasMore && !_isLoadingMore;

  /// Loads the first page for these filters and replaces [items].
  /// Completes with null when a newer request superseded this one.
  Future<Either<Failure, Unit>?> reload({
    String search = '',
    int? areaId,
    int? branchId,
  }) async {
    final generation = ++_generation;
    _isLoadingMore = false;
    final query = PageQuery(
      pageSize: pageSize,
      search: search,
      areaId: areaId,
      branchId: branchId,
    );
    final result = await _fetch(query);
    if (generation != _generation) return null;
    return result.map((page) {
      items
        ..clear()
        ..addAll(page);
      _next = query.nextPage();
      _hasMore = page.length == pageSize;
      return unit;
    });
  }

  /// Appends the next page. Completes with null when there is nothing more to
  /// load, a page is already loading, or the filters changed meanwhile.
  Future<Either<Failure, Unit>?> loadMore() async {
    if (!canLoadMore) return null;
    final generation = _generation;
    final query = _next;
    _isLoadingMore = true;
    final result = await _fetch(query);
    if (generation != _generation) return null;
    _isLoadingMore = false;
    return result.map((page) {
      // Rows inserted at the top since the last page shift the offsets, so
      // the start of this page can repeat rows that are already loaded.
      final loaded = items.map(idOf).toSet();
      items.addAll(page.where((item) => !loaded.contains(idOf(item))));
      _next = query.nextPage();
      _hasMore = page.length == pageSize;
      return unit;
    });
  }

  /// Drops all rows and ignores any request still in flight.
  void clear() {
    _generation++;
    items.clear();
    _next = const PageQuery();
    _hasMore = false;
    _isLoadingMore = false;
  }
}

/// Runs only the last of several calls made within [duration], so typing in a
/// search box sends one query instead of one per key. Every returned future
/// completes: superseded calls complete right away without running.
class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;
  Completer<void>? _pending;

  Future<void> run(Future<void> Function() action) {
    cancel();
    final completer = _pending = Completer<void>();
    _timer = Timer(duration, () {
      _pending = null;
      completer.complete(action());
    });
    return completer.future;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending?.complete();
    _pending = null;
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_change.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_lookup_option.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_stats.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:efs_misr/core/paging/page_loader.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tickets_state.dart';

/// Holds the ticket list one page at a time (search and filters run on the
/// server), plus the home overview: the newest tickets and server-side counts.
/// Realtime changes are applied to the loaded pages in place.
class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit({
    required this.ticketsRepo,
    Duration searchDebounce = const Duration(milliseconds: 300),
    Duration overviewRefreshDelay = const Duration(milliseconds: 500),
  }) : _searchDebouncer = Debouncer(searchDebounce),
       _overviewDebouncer = Debouncer(overviewRefreshDelay),
       super(HomeInitial()) {
    _pages = PageLoader(ticketsRepo.getTickets, idOf: (ticket) => ticket.id);
  }

  static const recentCount = 5;

  final TicketsRepo ticketsRepo;
  final Debouncer _searchDebouncer;

  /// Realtime events often come in bursts; the counts are refetched once
  /// the burst settles instead of once per event.
  final Debouncer _overviewDebouncer;
  late final PageLoader<TicketEntity> _pages;
  final List<TicketChange> _pendingChanges = [];
  StreamSubscription<TicketChange>? _ticketChangesSubscription;
  List<TicketEntity> _recentTickets = const [];
  TicketStats _stats = TicketStats.empty;
  bool _hasLoadedTickets = false;
  String? _listError;

  /// Bumped on sign-out so responses for the previous user are ignored.
  int _session = 0;
  String _searchQuery = '';
  int? _areaFilter;
  int? _branchFilter;

  int? get selectedAreaId => _areaFilter;
  int? get selectedBranchId => _branchFilter;

  /// Opens the realtime channel and loads tickets for the signed-in user.
  Future<void> start() async {
    if (_ticketChangesSubscription == null) _subscribeToTicketChanges();
    await getTickets();
  }

  /// Closes the realtime channel and drops everything cached for the
  /// previous user. Called on sign-out.
  Future<void> reset() async {
    _session++;
    _searchDebouncer.cancel();
    _overviewDebouncer.cancel();
    await _ticketChangesSubscription?.cancel();
    _ticketChangesSubscription = null;
    _pages.clear();
    _pendingChanges.clear();
    _recentTickets = const [];
    _stats = TicketStats.empty;
    _hasLoadedTickets = false;
    _listError = null;
    _searchQuery = '';
    _areaFilter = null;
    _branchFilter = null;
    if (!isClosed) emit(HomeInitial());
  }

  /// Loads the first page for the current search and filters, and the home
  /// overview alongside it.
  Future<void> getTickets() async {
    if (!_hasLoadedTickets) emit(GetTicketsLoading());
    await (_reloadList(), _loadOverview()).wait;
  }

  Future<void> loadMore() async {
    if (!_hasLoadedTickets || _listError != null || !_pages.canLoadMore) {
      return;
    }
    final loading = _pages.loadMore();
    _emitVisibleTickets();
    final result = await loading;
    if (result == null) return;
    result.fold(
      (failure) => developer.log(
        'Could not load more tickets: ${failure.message}',
        name: 'TicketsCubit',
      ),
      (_) {},
    );
    _emitVisibleTickets();
  }

  Future<void> searchTickets(String? search) {
    final query = search?.trim() ?? '';
    if (query == _searchQuery) return Future.value();
    _searchQuery = query;
    return _searchDebouncer.run(_reloadList);
  }

  Future<void> filterTickets({int? area, int? branch}) {
    _areaFilter = area;
    _branchFilter = branch;
    return _reloadList();
  }

  Future<Either<Failure, TicketFormOptions>> getTicketFormOptions() {
    return ticketsRepo.getTicketFormOptions();
  }

  Future<Either<Failure, ExcelExportStatus>> convertTicketsToExcel() async {
    final rows = await ticketsRepo.getExportRows();
    return rows.fold((failure) async => Left(failure), (data) async {
      if (data.isEmpty) return const Right(ExcelExportStatus.noData);
      try {
        return Right(await convertDataToExcel(data));
      } catch (error) {
        return Left(Failure.fromException(error));
      }
    });
  }

  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required int ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  }) async {
    final result = await ticketsRepo.updateTicketStatus(
      ticketId: BigInt.from(ticketId),
      status: status,
      repairDate: status == TicketStatus.completed
          ? (repairDate ?? DateTime.now())
          : null,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> updateDamageDescription({
    required int ticketId,
    required String damageDescription,
  }) async {
    final result = await ticketsRepo.updateDamageDescription(
      ticketId: BigInt.from(ticketId),
      damageDescription: damageDescription,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> updateTicketResponseDate({
    required int ticketId,
    required DateTime responseDate,
  }) async {
    final result = await ticketsRepo.updateTicketResponseDate(
      ticketId: BigInt.from(ticketId),
      responseDate: responseDate,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  }) async {
    if (oracleId <= BigInt.zero ||
        branchId <= BigInt.zero ||
        engineerId <= BigInt.zero) {
      return Left(
        GeneralFailure(
          'Select a branch and engineer and enter a valid Oracle ID.',
        ),
      );
    }
    if (comment.trim().isEmpty) {
      return Left(GeneralFailure('Comment is required.'));
    }
    final result = await ticketsRepo.addTicket(
      oracleId: oracleId,
      comment: comment,
      branchId: branchId,
      priority: priority,
      requestDate: requestDate,
      engineerId: engineerId,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, Unit>> deleteTicket({required int ticketId}) async {
    final result = await ticketsRepo.deleteTicket(
      ticketId: BigInt.from(ticketId),
    );
    result.fold((_) {}, (_) => _removeTicket(ticketId));
    return result;
  }

  Future<void> _reloadList() async {
    final session = _session;
    final result = await _pages.reload(
      search: _searchQuery,
      areaId: _areaFilter,
      branchId: _branchFilter,
    );
    if (result == null || isClosed || session != _session) return;
    result.fold(
      (failure) {
        if (_hasLoadedTickets) {
          _listError = failure.message;
          _emitVisibleTickets();
        } else {
          emit(GetTicketsFailure(errMsg: failure.message));
        }
      },
      (_) {
        _listError = null;
        final firstLoad = !_hasLoadedTickets;
        _hasLoadedTickets = true;
        _sortTickets();
        if (firstLoad) {
          for (final change in List<TicketChange>.of(_pendingChanges)) {
            _applyChange(change);
          }
          _pendingChanges.clear();
        }
        _emitVisibleTickets();
      },
    );
  }

  Future<void> _loadOverview() async {
    final session = _session;
    final (stats, recent) = await (
      ticketsRepo.getTicketStats(),
      ticketsRepo.getTickets(const PageQuery(pageSize: recentCount)),
    ).wait;
    if (isClosed || session != _session) return;
    stats.fold(
      (failure) => _logOverviewFailure(failure),
      (value) => _stats = value,
    );
    recent.fold(
      (failure) => _logOverviewFailure(failure),
      (tickets) => _recentTickets = List.unmodifiable(tickets),
    );
    _emitVisibleTickets();
  }

  void _logOverviewFailure(Failure failure) {
    developer.log(
      'Could not load the ticket overview: ${failure.message}',
      name: 'TicketsCubit',
    );
  }

  void _scheduleOverviewRefresh() {
    if (!_hasLoadedTickets) return;
    unawaited(_overviewDebouncer.run(_loadOverview));
  }

  void _subscribeToTicketChanges() {
    try {
      _ticketChangesSubscription = ticketsRepo.watchTicketChanges().listen(
        (change) {
          if (_hasLoadedTickets) {
            _applyChange(change);
          } else {
            _pendingChanges.add(change);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Ticket realtime subscription failed.',
            error: error,
            stackTrace: stackTrace,
            name: 'TicketsCubit',
          );
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Could not start ticket realtime subscription.',
        error: error,
        stackTrace: stackTrace,
        name: 'TicketsCubit',
      );
    }
  }

  void _applyChange(TicketChange change) {
    final ticket = change.ticket;
    if (ticket == null) {
      _removeTicket(change.id);
    } else {
      _upsertTicket(ticket);
    }
  }

  void _removeTicket(int ticketId) {
    _pages.items.removeWhere((ticket) => ticket.id == ticketId);
    _emitVisibleTickets();
    _scheduleOverviewRefresh();
  }

  /// Replaces a loaded ticket, or adds it when it matches the current search
  /// and filters and sorts inside the loaded pages. Tickets that sort after
  /// the last loaded row arrive with a later page instead.
  void _upsertTicket(TicketEntity ticket) {
    final tickets = _pages.items;
    final index = tickets.indexWhere((current) => current.id == ticket.id);
    final matches = _matchesFilters(ticket);
    if (index != -1) {
      if (matches) {
        tickets[index] = ticket;
      } else {
        tickets.removeAt(index);
      }
    } else if (matches && _isWithinLoadedPages(ticket)) {
      tickets.add(ticket);
    }
    _sortTickets();
    _emitVisibleTickets();
    _scheduleOverviewRefresh();
  }

  bool _isWithinLoadedPages(TicketEntity ticket) {
    if (!_pages.hasMore || _pages.items.isEmpty) return true;
    return _compareNewestFirst(ticket, _pages.items.last) <= 0;
  }

  /// Same order as the server query: newest first, then highest id.
  void _sortTickets() => _pages.items.sort(_compareNewestFirst);

  static int _compareNewestFirst(TicketEntity first, TicketEntity second) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final byCreated = (second.createdAt ?? epoch).compareTo(
      first.createdAt ?? epoch,
    );
    return byCreated != 0 ? byCreated : second.id.compareTo(first.id);
  }

  /// Mirrors the server-side search and filters for single tickets that
  /// arrive through realtime or local edits.
  bool _matchesFilters(TicketEntity ticket) {
    final branch = ticket.branchEntity;
    if (_areaFilter != null && branch?.areaId != _areaFilter) return false;
    if (_branchFilter != null && branch?.id != _branchFilter) return false;
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    return ticket.comment.toLowerCase().contains(query) ||
        ticket.damageDescription.toLowerCase().contains(query) ||
        (ticket.oricalID != null &&
            BigInt.tryParse(_searchQuery) == BigInt.from(ticket.oricalID!)) ||
        (ticket.status != TicketStatus.unknown &&
            ticket.status.databaseValue.toLowerCase().startsWith(query));
  }

  void _emitVisibleTickets() {
    if (isClosed || !_hasLoadedTickets) return;
    emit(
      GetTicketsSuccess(
        tickets: _listError == null
            ? List.unmodifiable(_pages.items)
            : const [],
        recentTickets: _recentTickets,
        stats: _stats,
        hasMore: _listError == null && _pages.hasMore,
        isLoadingMore: _pages.isLoadingMore,
        listError: _listError,
      ),
    );
  }

  @override
  Future<void> close() async {
    _searchDebouncer.cancel();
    _overviewDebouncer.cancel();
    await _ticketChangesSubscription?.cancel();
    await super.close();
  }
}

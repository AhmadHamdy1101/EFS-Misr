import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_change.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_stats.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/entities/branch_entity.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ticket [id] was created [id] minutes after the epoch, so higher ids are
/// newer and sort first, like the server's `created_at desc` order.
TicketEntity _ticket(
  int id, {
  int branch = 10,
  int area = 1,
  String comment = '',
  TicketStatus status = TicketStatus.awaiting,
}) {
  return TicketEntity(
    id: id,
    oricalID: 1000 + id,
    requestDate: null,
    repairDate: null,
    responseDate: null,
    repairDuration: null,
    createdAt: DateTime.utc(2026).add(Duration(minutes: id)),
    priority: 'High',
    engineer: null,
    closedBy: null,
    amount: 0,
    damageDescription: '',
    attachment: '',
    comment: comment,
    status: status,
    variation: '',
    branchEntity: BranchEntity(
      name: 'Branch $branch',
      id: branch,
      areaId: area,
    ),
    engineerUserEntity: null,
    closedByUserEntity: null,
  );
}

/// Pages, searches and filters an in-memory list the way the Supabase query
/// does. Set [gate] to hold list requests until it completes.
class _FakeTicketsRepo implements TicketsRepo {
  _FakeTicketsRepo(this.tickets);

  final List<TicketEntity> tickets;
  final queries = <PageQuery>[];
  final changes = StreamController<TicketChange>.broadcast();
  Completer<void>? gate;
  int statsCalls = 0;

  @override
  Future<Either<Failure, List<TicketEntity>>> getTickets(
    PageQuery query,
  ) async {
    queries.add(query);
    final waitFor = gate;
    if (waitFor != null) await waitFor.future;
    final search = query.search.toLowerCase();
    final matching = tickets.where((ticket) {
      final branch = ticket.branchEntity!;
      if (query.areaId != null && branch.areaId != query.areaId) {
        return false;
      }
      if (query.branchId != null && branch.id != query.branchId) {
        return false;
      }
      return search.isEmpty || ticket.comment.toLowerCase().contains(search);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
    return Right(matching.skip(query.from).take(query.pageSize).toList());
  }

  @override
  Future<Either<Failure, TicketStats>> getTicketStats() async {
    statsCalls++;
    return Right(
      TicketStats(
        total: tickets.length,
        completed: tickets
            .where((t) => t.status == TicketStatus.completed)
            .length,
        awaiting: tickets
            .where((t) => t.status == TicketStatus.awaiting)
            .length,
      ),
    );
  }

  @override
  Stream<TicketChange> watchTicketChanges() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GetTicketsSuccess _state(TicketsCubit cubit) =>
    cubit.state as GetTicketsSuccess;

List<int> _ids(TicketsCubit cubit) =>
    _state(cubit).tickets.map((t) => t.id).toList();

/// Lets stream events and zero-length timers run.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _FakeTicketsRepo repo;
  late TicketsCubit cubit;

  setUp(() async {
    repo = _FakeTicketsRepo([
      for (var id = 1; id <= 70; id++)
        _ticket(
          id,
          branch: id.isEven ? 10 : 20,
          area: id.isEven ? 1 : 2,
          comment: id % 10 == 0 ? 'broken door' : 'ok',
          status: id <= 20 ? TicketStatus.completed : TicketStatus.awaiting,
        ),
    ]);
    cubit = TicketsCubit(
      ticketsRepo: repo,
      searchDebounce: Duration.zero,
      overviewRefreshDelay: Duration.zero,
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
    await repo.changes.close();
  });

  test('loads the first page, newest first, plus the overview', () {
    final state = _state(cubit);
    expect(state.tickets, hasLength(PageQuery.defaultPageSize));
    expect(state.tickets.first.id, 70);
    expect(state.hasMore, isTrue);
    expect(state.recentTickets.map((t) => t.id), [70, 69, 68, 67, 66]);
    expect(state.stats.total, 70);
    expect(state.stats.completed, 20);
    expect(state.stats.awaiting, 50);
  });

  test('loadMore appends pages until the end', () async {
    await cubit.loadMore();
    await cubit.loadMore();
    expect(_ids(cubit), [for (var id = 70; id >= 1; id--) id]);
    expect(_state(cubit).hasMore, isFalse);
  });

  test('search and filters go to the server and restart paging', () async {
    await cubit.loadMore();
    await cubit.filterTickets(area: 1);
    await cubit.searchTickets('door');
    final query = repo.queries.last;
    expect(query.page, 0);
    expect(query.areaId, 1);
    expect(query.search, 'door');
    expect(_ids(cubit), [70, 60, 50, 40, 30, 20, 10]);
    expect(_state(cubit).hasMore, isFalse);
    // The home overview ignores the list's search and filters.
    expect(_state(cubit).recentTickets.first.id, 70);
  });

  test('a page for an older search is dropped', () async {
    repo.gate = Completer<void>();
    final loadingMore = cubit.loadMore();
    final searching = cubit.searchTickets('door');
    await _settle();
    repo.gate!.complete();
    await Future.wait([loadingMore, searching]);
    expect(_ids(cubit), [70, 60, 50, 40, 30, 20, 10]);
  });

  test('realtime insert shows a new ticket that matches the filters', () async {
    await cubit.filterTickets(branch: 10);
    final statsBefore = repo.statsCalls;

    final newer = _ticket(71, branch: 10);
    repo.tickets.add(newer);
    repo.changes.add(TicketChange(id: 71, ticket: newer));
    await _settle();
    expect(_ids(cubit).first, 71);
    expect(repo.statsCalls, greaterThan(statsBefore));

    final otherBranch = _ticket(72, branch: 20);
    repo.changes.add(TicketChange(id: 72, ticket: otherBranch));
    await _settle();
    expect(_ids(cubit), isNot(contains(72)));
  });

  test(
    'realtime update replaces a loaded ticket and delete removes it',
    () async {
      final edited = _ticket(70, comment: 'edited');
      repo.changes.add(TicketChange(id: 70, ticket: edited));
      await _settle();
      expect(_state(cubit).tickets.first.comment, 'edited');
      expect(_ids(cubit), hasLength(PageQuery.defaultPageSize));

      repo.changes.add(const TicketChange(id: 69));
      await _settle();
      expect(_ids(cubit), isNot(contains(69)));
    },
  );

  test(
    'realtime insert older than the loaded pages waits for its page',
    () async {
      final older = _ticket(0);
      repo.changes.add(TicketChange(id: 0, ticket: older));
      await _settle();
      expect(_ids(cubit), isNot(contains(0)));
    },
  );

  test('rows shifted by a realtime insert are not loaded twice', () async {
    final newer = _ticket(71);
    repo.tickets.add(newer);
    repo.changes.add(TicketChange(id: 71, ticket: newer));
    await _settle();
    await cubit.loadMore();
    final ids = _ids(cubit);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('reset drops the list and ignores late responses', () async {
    repo.gate = Completer<void>();
    final searching = cubit.searchTickets('door');
    await _settle();
    await cubit.reset();
    repo.gate!.complete();
    await searching;
    expect(cubit.state, isA<HomeInitial>());
  });
}

import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../../../../core/models/tickets.dart';
import '../../domain/entities/ticket_change.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_lookup_option.dart';
import '../../domain/repo/tickets_repo.dart';
import '../mappers/ticket_mapper.dart';
import '../ticket_data_source.dart';

class TicketRepoImpl implements TicketsRepo {
  final TicketDataSource ticketDataSource;

  const TicketRepoImpl(this.ticketDataSource);

  @override
  Future<Either<Failure, List<TicketEntity>>> getTickets() async {
    try {
      final tickets = await ticketDataSource.getTickets();
      final ticketsWithUsers = await _attachClosedByUsers(tickets);
      return Right(ticketsWithUsers.map((ticket) => ticket.toEntity()).toList());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity?>> getTicketById(BigInt ticketId) async {
    try {
      final ticket = await ticketDataSource.getTicketById(ticketId);
      if (ticket == null) return const Right(null);
      return Right((await _attachClosedByUser(ticket)).toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, List<TicketEntity>>> getTicketsWithAssetsID({
    required BigInt assetId,
  }) async {
    try {
      final tickets = await ticketDataSource.getTicketsWithAssetsId(assetId);
      final ticketsWithUsers = await _attachClosedByUsers(tickets);
      return Right(ticketsWithUsers.map((ticket) => ticket.toEntity()).toList());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketFormOptions>> getTicketFormOptions() async {
    try {
      final branchesFuture = ticketDataSource.getBranches();
      final engineersFuture = ticketDataSource.getEngineers();
      final branches = (await branchesFuture)
          .map((option) => option.toEntity())
          .toList();
      final engineers = (await engineersFuture)
          .map((option) => option.toEntity())
          .toList();
      return Right(TicketFormOptions(branches: branches, engineers: engineers));
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  }) async {
    try {
      final ticket = await ticketDataSource.addTicket(
        oracleId: oracleId,
        comment: comment,
        branchId: branchId,
        priority: priority,
        requestDate: requestDate,
        engineerId: engineerId,
      );
      return Right((await _attachClosedByUser(ticket)).toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required BigInt ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  }) async {
    try {
      final ticket = await ticketDataSource.updateTicketStatus(
        ticketId: ticketId,
        status: status,
        repairDate: repairDate,
      );
      return Right((await _attachClosedByUser(ticket)).toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> updateDamageDescription({
    required BigInt ticketId,
    required String damageDescription,
  }) async {
    try {
      final ticket = await ticketDataSource.updateDamageDescription(
        ticketId: ticketId,
        damageDescription: damageDescription,
      );
      return Right((await _attachClosedByUser(ticket)).toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> updateTicketResponseDate({
    required BigInt ticketId,
    required DateTime responseDate,
  }) async {
    try {
      final ticket = await ticketDataSource.updateTicketResponseDate(
        ticketId: ticketId,
        responseDate: responseDate,
      );
      return Right((await _attachClosedByUser(ticket)).toEntity());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTicket({required BigInt ticketId}) async {
    try {
      await ticketDataSource.deleteTicket(ticketId);
      return const Right(unit);
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Stream<TicketChange> watchTicketChanges() async* {
    await for (final change in ticketDataSource.watchTicketChanges()) {
      if (change.deleted) {
        yield TicketChange(id: change.id.toInt());
        continue;
      }

      final ticket = await ticketDataSource.getTicketById(change.id);
      if (ticket == null) {
        yield TicketChange(id: change.id.toInt());
        continue;
      }
      final ticketWithUser = await _attachClosedByUser(ticket);
      yield TicketChange(
        id: change.id.toInt(),
        ticket: ticketWithUser.toEntity(),
      );
    }
  }

  Future<List<Tickets>> _attachClosedByUsers(List<Tickets> tickets) async {
    final ids = tickets
        .map((ticket) => ticket.closedBy)
        .whereType<BigInt>()
        .toSet()
        .toList();
    if (ids.isEmpty) return tickets;

    final users = await ticketDataSource.getUsersByIds(ids);
    final usersById = {for (final user in users) user.id: user};
    return tickets
        .map((ticket) => ticket.copyWith(closedByUser: usersById[ticket.closedBy]))
        .toList();
  }

  Future<Tickets> _attachClosedByUser(Tickets ticket) async {
    final id = ticket.closedBy;
    if (id == null) return ticket;

    final users = await ticketDataSource.getUsersByIds([id]);
    for (final user in users) {
      if (user.id == id) return ticket.copyWith(closedByUser: user);
    }
    return ticket;
  }
}

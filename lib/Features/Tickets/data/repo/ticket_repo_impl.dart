import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../../domain/entities/ticket_change.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_lookup_option.dart';
import '../../domain/entities/ticket_stats.dart';
import '../../domain/repo/tickets_repo.dart';
import '../../../../core/paging/page_query.dart';
import '../mappers/ticket_mapper.dart';
import '../ticket_data_source.dart';

class TicketRepoImpl implements TicketsRepo {
  final TicketDataSource ticketDataSource;

  const TicketRepoImpl(this.ticketDataSource);

  @override
  Future<Either<Failure, List<TicketEntity>>> getTickets(
    PageQuery query,
  ) async {
    try {
      final tickets = await ticketDataSource.getTickets(query);
      return Right(tickets.map((ticket) => ticket.toEntity()).toList());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketStats>> getTicketStats() async {
    try {
      return Right(await ticketDataSource.getTicketStats());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getExportRows() async {
    try {
      return Right(await ticketDataSource.getExportRows());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, TicketEntity?>> getTicketById(BigInt ticketId) async {
    try {
      final ticket = await ticketDataSource.getTicketById(ticketId);
      if (ticket == null) return const Right(null);
      return Right(ticket.toEntity());
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
      return Right(tickets.map((ticket) => ticket.toEntity()).toList());
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
      return Right(ticket.toEntity());
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
      return Right(ticket.toEntity());
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
      return Right(ticket.toEntity());
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
      return Right(ticket.toEntity());
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
      yield TicketChange(id: change.id.toInt(), ticket: ticket.toEntity());
    }
  }
}

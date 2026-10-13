import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../entities/ticket_change.dart';
import '../entities/ticket_entity.dart';
import '../entities/ticket_lookup_option.dart';

abstract interface class TicketsRepo {
  Future<Either<Failure, List<TicketEntity>>> getTickets();
  Future<Either<Failure, TicketEntity?>> getTicketById(BigInt ticketId);
  Future<Either<Failure, List<TicketEntity>>> getTicketsWithAssetsID({
    required BigInt assetId,
  });
  Future<Either<Failure, TicketFormOptions>> getTicketFormOptions();
  Future<Either<Failure, TicketEntity>> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  });
  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required BigInt ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  });
  Future<Either<Failure, TicketEntity>> updateDamageDescription({
    required BigInt ticketId,
    required String damageDescription,
  });
  Future<Either<Failure, TicketEntity>> updateTicketResponseDate({
    required BigInt ticketId,
    required DateTime responseDate,
  });
  Future<Either<Failure, Unit>> deleteTicket({required BigInt ticketId});
  Stream<TicketChange> watchTicketChanges();
}

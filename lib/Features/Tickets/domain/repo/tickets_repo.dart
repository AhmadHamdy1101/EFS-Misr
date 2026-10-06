import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../../../../core/models/tickets.dart';

abstract class TicketsRepo {
  Future<Either<Failure, List<Tickets>>> getTickets();




  // Future<Either<Failure, List<Users>>> getUsers();



  Future<Either<Failure, List<Tickets>>> getTicketsWithAssetsID({
    required BigInt assetId,
  });



  Future<Either<Failure, Tickets>> updateTicketStatus({
    required String ticketID,
    required String newStatus,
    required DateTime repairDate,
  });

  Future<Either<Failure, Tickets>> updateTicketComment({
    required String ticketID,
    required String newComment,
  });

  Future<Either<Failure, List<Tickets>>> addTicket({
    required BigInt orecalID,
    required String comment,
    required BigInt branchID,
    required String priority,
    required DateTime requestDate,
    required BigInt engineer,
  });
}
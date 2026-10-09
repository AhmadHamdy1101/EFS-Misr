import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tickets/data/ticket_data_soucre.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';

import '../../../../constants/constants.dart';
import '../../../../core/Errors/failure.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/tickets.dart';

class TicketRepoImpl extends TicketsRepo{
  final TicketDataSource ticketDataSource;
  TicketRepoImpl(this.ticketDataSource);

  @override
  Future<Either<Failure, List<Tickets>>> getTickets() async {
    try {
      final tickets = await ticketDataSource.getTickets();
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Tickets>> updateTicketStatus({
    required String ticketID,
    required String newStatus,
    required DateTime repairDate,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .update(Tickets.update(status: newStatus, repairDate: repairDate))
          .eq('id', ticketID)
          .select('''
      *,
      branch(*),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tickets>>> addTicket({
    required BigInt orecalID,
    required String comment,
    required BigInt branchID,
    required String priority,
    required DateTime requestDate,
    required BigInt engineer,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .insert(
        Tickets.insert(
          orecalId: orecalID,
          comment: comment,
          branch: branchID,
          priority: priority,
          requestDate: requestDate,
          engineer: engineer,
        ),
      )
          .select()
          .withConverter(Tickets.converter);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }





  @override
  Future<Either<Failure, List<Tickets>>> getTicketsWithAssetsID({
    required BigInt assetId,
  }) async {
    try {
      final assetsAndTickets = await ticketDataSource
          .getTicketsWithAssetsID(assetId: assetId);
      return Right(assetsAndTickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Tickets>> updateTicketComment({
    required String ticketID,
    required String newComment,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .update(Tickets.update(damageDescription: newComment))
          .eq('id', ticketID)
          .select('''
      *,
      branch(*),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }


  @override
  Future<Either<Failure, Tickets>> updateTicketResponseDate({
    required String ticketID,
    required DateTime responseDate,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .update(Tickets.update(responseDate: responseDate))
          .eq('id', ticketID)
          .select('''
      *,
      branch(*,area(*)),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> deleteTicket({
    required BigInt ticketID,
  }) async {
    try {
      await supabaseClient.tickets.delete().eq(Tickets.c_id, ticketID);
      return Right('Deleted Successfully');
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

}

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/core/Errors/failure.dart';

abstract class HomeRepo {
  Future<Either<Failure, List<Tickets>>> getTickets();

  Future<Either<Failure, List<Assets>>> getAssets();

  Future<Either<Failure, List<Users>>> getUsers();

  Future<Either<Failure, List<Assets>>> getAssetsWithTicketID({
    required BigInt ticketId,
  });

  Future<Either<Failure, List<Tickets>>> getTicketsWithAssetsID({
    required BigInt assetId,
  });

  Future<Either<Failure, Assets>> getAssetsByQrCode(String barcode);

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

  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  });

  Future<Either<Failure, String>> addAssetsRepairs({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  });

  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithTicketID({
    required BigInt ticketID,
  });
}

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/core/Errors/failure.dart';

abstract class HomeRepo{
  Future<Either<Failure,List<Tickets>>> getTickets();
  Future<Either<Failure,List<Assets>>> getAssets();
  Future<Either<Failure,List<Users>>> getUsers();
  Future<Either<Failure,List<Assets>>> getAssetsAndTickets({required BigInt ticketId});

  Future<Either<Failure,Assets>> getAssetsByQrCode(String barcode);

  Future<Either<Failure,Tickets>> updateTicketStatus({
    required String ticketID,
    required String newStatus,
});

  Future<Either<Failure,List<Tickets>>> addTicket({
    required BigInt orecalID,
    required String comment,
    required BigInt branchID,
    required String priority,
    required DateTime requestDate,
    required BigInt engineer,
});


  Future<Either<Failure,String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
});
}
import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/core/Errors/failure.dart';

abstract class HomeRepo{
  Future<Either<Failure,List<Tickets>>> getTickets();
  Future<Either<Failure,List<Assets>>> getAssets();
  // Stream<Either<Failure,List<Users>>> getUsers();

  Future<Either<Failure,Assets>> getAssetsByQrCode(String barcode);
}
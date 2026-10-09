import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';

import '../../../../core/Errors/failure.dart';
import '../../../../core/models/assets.dart';
import '../../../../core/models/assets_repair.dart';
import '../../../../core/models/tickets.dart';

abstract class AssetsDataRepo {
  Future<Either<Failure, List<AssetsEntity>>> getAssets();
  Future<Either<Failure, List<Assets>>> getAssetsWithTicketID({
    required BigInt ticketId,
  });
  Future<Either<Failure, AssetsEntity>> getAssetsByQrCode(String barcode);

  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithTicketID({
    required BigInt ticketID,
  });
  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  });
  Future<Either<Failure, Tickets>> addAssetsRepairs({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  });
  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) ;
  Future<Either<Failure, List<Assets>>> addAssets({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  });
}
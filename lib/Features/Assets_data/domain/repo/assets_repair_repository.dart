import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../entities/add_asset_repair_result.dart';
import '../entities/asset_repair_entity.dart';

abstract class AssetsRepairRepository {
  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForTicketAsset({
    required BigInt ticketId,
    required BigInt assetId,
  });

  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForTicket({
    required BigInt ticketId,
  });

  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForAsset({
    required BigInt assetId,
  });

  Future<Either<Failure, AddAssetRepairResult>> addRepair({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  });
}

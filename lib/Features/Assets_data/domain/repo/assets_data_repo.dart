import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';

import '../../../../core/Errors/failure.dart';

abstract class AssetsDataRepo {
  Future<Either<Failure, List<AssetsEntity>>> getAssets();
  Future<Either<Failure, List<AssetsEntity>>> getAssetsWithTicketID({
    required BigInt ticketId,
  });
  Future<Either<Failure, AssetsEntity>> getAssetsByQrCode(String barcode);

  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  });
  Future<Either<Failure, List<AssetsEntity>>> addAssets({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  });
}

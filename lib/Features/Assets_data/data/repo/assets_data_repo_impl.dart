import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/data/assets_data_source.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/asset_repair_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/add_asset_repair_result.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/asset_repair_totals.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_repair_repository.dart';
import 'package:efs_misr/core/models/assets_repair.dart';
import 'package:efs_misr/core/paging/page_query.dart';
import '../mappers/asset_repair_mapper.dart';
import '../../../../core/Errors/failure.dart';

class AssetsDataRepoImpl implements AssetsDataRepo, AssetsRepairRepository {
  final AssetsDataSource assetsDataSource;
  AssetsDataRepoImpl(this.assetsDataSource);
  @override
  Future<Either<Failure, List<AssetsEntity>>> getAssets(PageQuery query) async {
    try {
      final assets = await assetsDataSource.getAssets(query);
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, AssetsEntity>> getAssetsByQrCode(
    String barcode,
  ) async {
    try {
      final assets = await assetsDataSource.getAssetsByQrCode(barcode);

      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetsEntity>>> getAssetsWithTicketID({
    required BigInt ticketId,
  }) async {
    try {
      final assetsAndTickets = await assetsDataSource.getAssetsWithTicketID(
        ticketId: ticketId,
      );
      return Right(
        assetsAndTickets.map((asset) => asset.toAssetsEntity()).toList(),
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForTicketAsset({
    required BigInt ticketId,
    required BigInt assetId,
  }) async {
    try {
      final res = await assetsDataSource.getAssetsRepairDetailsWithTicketId(
        ticketID: ticketId,
        assetID: assetId,
      );
      return Right(res.map((repair) => repair.toEntity()).toList());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForTicket({
    required BigInt ticketId,
  }) async {
    try {
      final repairs = await assetsDataSource.getAssetsRepairDetailsForTicket(
        ticketID: ticketId,
      );
      return Right(repairs.map((repair) => repair.toEntity()).toList());
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  @override
  Future<Either<Failure, List<AssetRepairEntity>>> getRepairsForAsset({
    required BigInt assetId,
  }) async {
    try {
      final res = await assetsDataSource.getAssetsRepairWithAssetId(
        assetID: assetId,
      );

      return Right(res.map((repair) => repair.toEntity()).toList());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, AddAssetRepairResult>> addRepair({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    try {
      final result = await assetsDataSource.addAssetRepair(
        assetId: assetId,
        ticketId: ticketId,
        variation: variation,
        comment: comment,
        amount: amount,
      );
      final repairJson = Map<String, dynamic>.from(result['repair'] as Map);
      final repair = AssetsRepair.fromJson(repairJson).toEntity();
      final totalsJson = Map<String, dynamic>.from(result['totals'] as Map);
      final assetTicketTotal = num.parse(
        totalsJson['asset_ticket_total'].toString(),
      );

      return Right(
        AddAssetRepairResult(
          repair: repair,
          totals: AssetRepairTotals(assetTicketTotal: assetTicketTotal),
        ),
      );
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    try {
      await assetsDataSource.linkAssetToTicket(
        assetsId: assetsId,
        ticketId: ticketId,
      );
      return Right('Success');
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetsEntity>>> addAssets({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  }) async {
    try {
      final assets = await assetsDataSource.addAsset(
        barcode: barcode,
        name: name,
        floor: floor,
        place: place,
        type: type,
        branch: branch,
      );
      return Right(assets.map((asset) => asset.toAssetsEntity()).toList());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getExportRows() async {
    try {
      return Right(await assetsDataSource.getExportRows());
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}

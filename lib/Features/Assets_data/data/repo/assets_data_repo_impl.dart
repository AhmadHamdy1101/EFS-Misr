import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/data/assets_data_source.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/core/models/assets_repair.dart';
import '../../../../constants/constants.dart';
import '../../../../core/Errors/failure.dart';
import '../../../../core/models/assets.dart';
import '../../../../core/models/assets_and_tickets.dart';
import '../../../../core/models/supadart_header.dart';
import '../../../../core/models/tickets.dart';

class AssetsDataRepoImpl implements AssetsDataRepo{
  final AssetsDataSource assetsDataSource;
  AssetsDataRepoImpl(this.assetsDataSource);
  @override
  Future<Either<Failure, List<Assets>>> getAssets() async {
    try {
      final assets = await assetsDataSource.getAssets();
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Assets>> getAssetsByQrCode(String barcode) async {
    try {
      final assets = await assetsDataSource.getAssetsByQrCode(barcode);
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }


  @override
  Future<Either<Failure, List<Assets>>> getAssetsWithTicketID({
    required BigInt ticketId,
  }) async {
    try {
      final assetsAndTickets = await assetsDataSource.getAssetsWithTicketID(
        ticketId: ticketId,
      );
      return Right(assetsAndTickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithTicketID({
    required BigInt ticketID,
  }) async {
    try {
      final res = await assetsDataSource.getAssetsRepairDetailsWithTicketId(
        ticketID: ticketID,
      );
      return Right(res);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
  @override
  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  }) async {
    try {
      final res = await assetsDataSource.getAssetsRepairWithAssetId(
        assetID: assetID,
      );

      return Right(res);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Tickets>> addAssetsRepairs({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    try {
      await supabaseClient.AssetsRepair.insert(
        AssetsRepair.insert(
          amount: amount,
          TicketsId: ticketId,
          assetsId: assetsId,
          comment: comment,
          variation: variation,
        ),
      ).select().withConverter(AssetsRepair.converter);

      final ticketAmount = await supabaseClient.tickets
          .select('''
      *,
      branch(*),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .eq('id', ticketId)
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(ticketAmount);
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
      await supabaseClient.assetsAndTickets.insert(
        AssetsAndTickets.insert(assetsId: assetsId, TicketsId: ticketId),
      );
      return Right('Success');
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

}
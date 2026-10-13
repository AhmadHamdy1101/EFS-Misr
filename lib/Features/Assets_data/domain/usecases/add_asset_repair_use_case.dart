import 'package:dartz/dartz.dart';

import '../../../../core/Errors/failure.dart';
import '../entities/add_asset_repair_result.dart';
import '../repo/assets_repair_repository.dart';

class AddAssetRepairUseCase {
  final AssetsRepairRepository repository;

  const AddAssetRepairUseCase(this.repository);

  Future<Either<Failure, AddAssetRepairResult>> call({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) {
    if (!amount.isFinite || amount < 0) {
      return Future.value(Left(GeneralFailure('Enter a valid amount.')));
    }

    return repository.addRepair(
      assetId: assetId,
      ticketId: ticketId,
      variation: variation,
      comment: comment,
      amount: amount,
    );
  }
}

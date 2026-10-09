
import '../../../../core/models/assets.dart';
import '../../../../core/models/assets_repair.dart';

class AssetsWithAssetsRepairEntity {
  final Assets assets;
  final List<AssetsRepair> assetsRepair;
  final num totalAmount;

  const AssetsWithAssetsRepairEntity({
    required this.assets,
    required this.assetsRepair,
    required this.totalAmount,
  });
}

import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';

class AssetsWithAssetsRepairEntity {
  final Assets assets;
  final List<AssetsRepair> assetsRepair;

  const AssetsWithAssetsRepairEntity({
    required this.assets,
    required this.assetsRepair,
  });
}

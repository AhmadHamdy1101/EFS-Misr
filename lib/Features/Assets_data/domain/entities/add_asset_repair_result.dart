import 'asset_repair_entity.dart';
import 'asset_repair_totals.dart';

/// Result of recording a repair together with its refreshed persisted totals.
class AddAssetRepairResult {
  final AssetRepairEntity repair;
  final AssetRepairTotals totals;

  const AddAssetRepairResult({required this.repair, required this.totals});
}

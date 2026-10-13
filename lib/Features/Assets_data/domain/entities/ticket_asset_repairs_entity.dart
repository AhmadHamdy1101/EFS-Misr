import 'asset_repair_entity.dart';
import 'assets_entity.dart';

/// An asset linked to a ticket, with only that pair's repair records and total.
class TicketAssetRepairsEntity {
  final AssetsEntity asset;
  final List<AssetRepairEntity> repairs;
  final num totalAmount;

  const TicketAssetRepairsEntity({
    required this.asset,
    required this.repairs,
    required this.totalAmount,
  });
}

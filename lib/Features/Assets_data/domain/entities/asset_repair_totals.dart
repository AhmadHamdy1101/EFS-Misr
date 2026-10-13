import 'asset_repair_entity.dart';

/// Aggregate repair cost for one asset linked to one ticket.
class AssetRepairTotals {
  final num assetTicketTotal;

  const AssetRepairTotals({required this.assetTicketTotal});

  factory AssetRepairTotals.fromRepairs(
    Iterable<AssetRepairEntity> assetTicketRepairs,
  ) {
    return AssetRepairTotals(assetTicketTotal: sum(assetTicketRepairs));
  }

  static num sum(Iterable<AssetRepairEntity> repairs) {
    return repairs.fold<num>(
      0,
      (total, repair) => total + (repair.amount ?? 0),
    );
  }
}

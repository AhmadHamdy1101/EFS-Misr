import '../../domain/entities/asset_repair_entity.dart';
import '../../../../core/models/assets_repair.dart';
import '../../../Tickets/data/mappers/ticket_mapper.dart';

extension AssetRepairMapper on AssetsRepair {
  AssetRepairEntity toEntity() {
    return AssetRepairEntity(
      id: id,
      createdAt: createdAt,
      assetId: assetsId,
      ticketId: TicketsId,
      amount: amount,
      comment: comment,
      variation: variation,
      ticket: tickets?.toEntity(),
    );
  }
}

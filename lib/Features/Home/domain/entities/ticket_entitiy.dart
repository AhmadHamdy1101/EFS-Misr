import 'package:efs_misr/Features/Home/domain/entities/asset_with_asset_repair_entitiy.dart';

import '../../../../core/models/tickets.dart';

class TicketDetailsEntity {
  final Tickets ticket;
  final List<AssetsWithAssetsRepairEntity> assetsWithAssetsRepairData;

  const TicketDetailsEntity({
    required this.ticket,
    required this.assetsWithAssetsRepairData,
  });
}

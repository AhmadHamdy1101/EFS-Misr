import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';

import '../../../constants/constants.dart';
import '../../../core/models/assets.dart';
import '../../../core/models/assets_repair.dart';
import '../../../core/models/supadart_header.dart';

abstract class AssetsDataSource {
  Future<List<AssetsEntity>> getAssets();
  Future<AssetsEntity> getAssetsByQrCode(String qrCode);
  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
    required BigInt assetID,
  });
  Future<List<AssetsRepair>> getAssetsRepairDetailsForTicket({
    required BigInt ticketID,
  });
  Future<List<AssetsRepair>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  });

  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId});

  Future<Map<String, dynamic>> addAssetRepair({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  });
}

class AssetsDataSourceImpl extends AssetsDataSource {
  @override
  Future<List<AssetsEntity>> getAssets() async {
    final assets = await supabaseClient.assets
        .select('''
      *,
      branch(*)
    ''')
        .withConverter(Assets.converter);
    final assetsEntity = assets.map((e) => e.toAssetsEntity()).toList();

    return assetsEntity;
  }

  @override
  Future<AssetsEntity> getAssetsByQrCode(String qrCode) async {
    final asset = await supabaseClient.assets
        .select('*,branch(*)')
        .eq('barcode', qrCode)
        .withConverter(Assets.converter);
    return asset.first.toAssetsEntity();
  }

  @override
  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId}) async {
    final assetsAndTickets = await supabaseClient.assets
        .select('*,branch(*), assets_tickets_details!inner(*)')
        .eq('assets_tickets_details.Tickets_id', ticketId.toString())
        .withConverter(Assets.converter);
    return assetsAndTickets;
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
    required BigInt assetID,
  }) async {
    final data =
        await supabaseClient.AssetsRepair.select('''
      *,
      ticket:tickets(
        *,
        engineer:users!tickets_engineer_fkey(*, positions(*)),
        branch:branch(*)
      )
    ''')
            .eq(AssetsRepair.c_TicketsId, ticketID.toString())
            .eq(AssetsRepair.c_assetsId, assetID.toString())
            .withConverter(AssetsRepair.converter);
    return data;
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairDetailsForTicket({
    required BigInt ticketID,
  }) async {
    return supabaseClient.AssetsRepair.select(
          'id,created_at,comment,variation,amount,assets_id,ticket_id',
        )
        .eq(AssetsRepair.c_TicketsId, ticketID.toString())
        .order(AssetsRepair.c_createdAt)
        .withConverter(AssetsRepair.converter);
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  }) async {
    final data =
        await supabaseClient.AssetsRepair.select('''
      *,
      ticket:tickets(
        *,
        engineer:users!tickets_engineer_fkey(*, positions(*)),
        branch:branch(*)
      )
    ''')
            .eq(AssetsRepair.c_assetsId, assetID.toString())
            .withConverter(AssetsRepair.converter);
    return data;
  }

  @override
  Future<Map<String, dynamic>> addAssetRepair({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    final linkedAssets = await supabaseClient.assetsAndTickets
        .select('id')
        .eq('assets_id', assetId.toString())
        .eq('Tickets_id', ticketId.toString())
        // The relation table may contain duplicate rows for the same pair.
        // We only need to know whether at least one link exists.
        .limit(1);
    if (linkedAssets.isEmpty) {
      throw StateError('This asset is not linked to the selected ticket.');
    }

    final repair = await supabaseClient.AssetsRepair.insert(
      AssetsRepair.insert(
        assetsId: assetId,
        TicketsId: ticketId,
        variation: variation,
        comment: comment,
        amount: amount,
      ),
    ).select().single();

    final repairRows = await supabaseClient.AssetsRepair.select('amount')
        .eq(AssetsRepair.c_assetsId, assetId.toString())
        .eq(AssetsRepair.c_TicketsId, ticketId.toString());
    final assetTicketTotal = repairRows.fold<num>(
      0,
      (total, row) =>
          total + (num.tryParse(row['amount']?.toString() ?? '') ?? 0),
    );

    await supabaseClient.assetsAndTickets
        .update({'Ammount': assetTicketTotal})
        .eq('assets_id', assetId.toString())
        .eq('Tickets_id', ticketId.toString());

    return {
      'repair': Map<String, dynamic>.from(repair),
      'totals': {'asset_ticket_total': assetTicketTotal},
    };
  }
}

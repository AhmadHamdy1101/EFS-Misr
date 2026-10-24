import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/Errors/failure.dart';
import '../../../core/models/assets.dart';
import '../../../core/models/assets_and_tickets.dart';
import '../../../core/models/assets_repair.dart';
import '../../../core/models/supadart_header.dart';
import '../../../core/paging/page_query.dart';

abstract class AssetsDataSource {
  Future<List<AssetsEntity>> getAssets(PageQuery query);
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

  Future<void> linkAssetToTicket({
    required BigInt assetsId,
    required BigInt ticketId,
  });

  Future<List<Assets>> addAsset({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  });

  Future<List<Map<String, dynamic>>> getExportRows();
}

class AssetsDataSourceImpl extends AssetsDataSource {
  AssetsDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _repairWithTicket = '''
      *,
      ticket:tickets(
        *,
        engineer:users!tickets_engineer_fkey(
          id,userid,name,email,address,phone,role,status,Company,company_email,image,
          positions(*)
        ),
        branch:branch(*)
      )
    ''';

  @override
  Future<List<AssetsEntity>> getAssets(PageQuery query) async {
    // The area id lives on the branch, so filtering by it needs an inner join.
    var request = _client.assets.select(
      query.areaId == null ? '*, branch(*)' : '*, branch!inner(*)',
    );
    if (query.branchId != null) {
      request = request.eq(Assets.c_Branch, query.branchId!);
    }
    if (query.areaId != null) {
      request = request.eq('branch.area', query.areaId!);
    }
    if (query.hasSearch) {
      request = request.or(
        ilikeAny([
          Assets.c_type,
          Assets.c_barcode,
          Assets.c_name,
          Assets.c_place,
          Assets.c_area,
        ], query.search),
      );
    }
    final assets = await request
        .order(Assets.c_createdAt, ascending: false)
        .order(Assets.c_id, ascending: false)
        .range(query.from, query.to)
        .withConverter(Assets.converter);
    return assets.map((e) => e.toAssetsEntity()).toList();
  }

  @override
  Future<AssetsEntity> getAssetsByQrCode(String qrCode) async {
    final asset = await _client.assets
        .select('*,branch(*)')
        .eq('barcode', qrCode)
        .limit(1)
        .withConverter(Assets.converter);
    if (asset.isEmpty) {
      throw GeneralFailure('No asset found for code "$qrCode".');
    }
    return asset.first.toAssetsEntity();
  }

  @override
  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId}) {
    return _client.assets
        .select('*,branch(*), assets_tickets_details!inner(*)')
        .eq('assets_tickets_details.Tickets_id', ticketId.toString())
        .withConverter(Assets.converter);
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
    required BigInt assetID,
  }) {
    return _client.AssetsRepair.select(_repairWithTicket)
        .eq(AssetsRepair.c_TicketsId, ticketID.toString())
        .eq(AssetsRepair.c_assetsId, assetID.toString())
        .withConverter(AssetsRepair.converter);
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairDetailsForTicket({
    required BigInt ticketID,
  }) {
    return _client.AssetsRepair.select(
          'id,created_at,comment,variation,amount,assets_id,ticket_id',
        )
        .eq(AssetsRepair.c_TicketsId, ticketID.toString())
        .order(AssetsRepair.c_createdAt)
        .withConverter(AssetsRepair.converter);
  }

  @override
  Future<List<AssetsRepair>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  }) {
    return _client.AssetsRepair.select(_repairWithTicket)
        .eq(AssetsRepair.c_assetsId, assetID.toString())
        .withConverter(AssetsRepair.converter);
  }

  @override
  Future<Map<String, dynamic>> addAssetRepair({
    required BigInt assetId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    if (amount < 0) throw GeneralFailure('Amount must be zero or more.');
    if (!await _isLinked(assetId, ticketId)) {
      throw GeneralFailure('This asset is not linked to the selected ticket.');
    }

    // The database triggers on assets_repair (`trg_update_assets_tickets_total`,
    // `on_assets_repair_change`) update the asset/ticket totals in the same
    // transaction as this insert, so the totals are read back afterwards
    // rather than computed here.
    final repair = await _client.AssetsRepair.insert(
      AssetsRepair.insert(
        assetsId: assetId,
        TicketsId: ticketId,
        variation: variation,
        comment: comment,
        amount: amount,
      ),
    ).select().single();

    final link = await _client.assetsAndTickets
        .select('Ammount')
        .eq('assets_id', assetId.toString())
        .eq('Tickets_id', ticketId.toString())
        .limit(1);
    final total = link.isEmpty ? null : link.first['Ammount'];

    return {
      'repair': Map<String, dynamic>.from(repair),
      'totals': {'asset_ticket_total': total ?? amount},
    };
  }

  @override
  Future<void> linkAssetToTicket({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    // The table has no unique constraint yet, so check first; otherwise a
    // re-scan adds the asset to the ticket twice.
    if (await _isLinked(assetsId, ticketId)) {
      throw GeneralFailure('This asset is already added to this ticket.');
    }
    await _client.assetsAndTickets.insert(
      AssetsAndTickets.insert(assetsId: assetsId, TicketsId: ticketId),
    );
  }

  Future<bool> _isLinked(BigInt assetId, BigInt ticketId) async {
    final rows = await _client.assetsAndTickets
        .select('id')
        .eq('assets_id', assetId.toString())
        .eq('Tickets_id', ticketId.toString())
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<List<Assets>> addAsset({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  }) {
    return _client.assets
        .insert(
          Assets.insert(
            barcode: barcode,
            name: name,
            floor: floor,
            place: place,
            type: type,
            Branch: branch,
          ),
        )
        .select('*, branch(*)')
        .withConverter(Assets.converter);
  }

  @override
  Future<List<Map<String, dynamic>>> getExportRows() async {
    final rows = await _client.assetsAndTickets.select(
      'id,tickets(orecal_id),assets(barcode,name,branch(name),floor,place,area,type),Ammount',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}

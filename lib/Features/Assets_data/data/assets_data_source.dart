import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/Errors/failure.dart';
import '../../../core/models/assets.dart';
import '../../../core/models/assets_and_tickets.dart';
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
  Future<List<AssetsEntity>> getAssets() async {
    final assets = await _client.assets
        .select('*, branch(*)')
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
    // One round trip: the database checks the link, inserts the repair and
    // updates the running total inside a single transaction.
    final result = await _client.rpc(
      'add_asset_repair',
      params: {
        'p_asset_id': assetId.toString(),
        'p_ticket_id': ticketId.toString(),
        'p_variation': variation,
        'p_comment': comment,
        'p_amount': amount,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> linkAssetToTicket({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    await _client.assetsAndTickets.insert(
      AssetsAndTickets.insert(assetsId: assetsId, TicketsId: ticketId),
    );
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

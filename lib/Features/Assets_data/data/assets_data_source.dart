

import '../../../constants/constants.dart';
import '../../../core/models/assets.dart';
import '../../../core/models/assets_repair.dart';
import '../../../core/models/supadart_header.dart';

abstract class AssetsDataSource {
  Future<List<Assets>> getAssets();
  Future<Assets> getAssetsByQrCode(String qrCode);
  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
  });
  Future<List<AssetsRepair>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  });

  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId});
}

class AssetsDataSourceImpl extends AssetsDataSource{
  @override
  Future<List<Assets>> getAssets() async {
    final assets = await supabaseClient.assets
        .select('''
      *,
      branch(*)
    ''')
        .withConverter(Assets.converter);

    return assets;
  }

  @override
  Future<Assets> getAssetsByQrCode(String qrCode) async {
    final asset = await supabaseClient.assets
        .select('*,branch(*)')
        .eq('barcode', qrCode)
        .withConverter(Assets.converter);
    return asset[0];
  }
  @override
  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId}) async {
    final assetsAndTickets = await supabaseClient.assets
        .select('*,branch(*), assets_tickets_details!inner(*)')
        .eq('assets_tickets_details.Tickets_id', ticketId)
        .withConverter(Assets.converter);
    return assetsAndTickets;
  }
  @override
  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
  }) async {
    final data = await supabaseClient.AssetsRepair.select('''
      *,
      ticket:tickets(
        *,
        engineer:users!tickets_engineer_fkey(*, positions(*)),
        branch:branch(*)
      )
    ''').eq('ticket_id', ticketID).withConverter(AssetsRepair.converter);
    return data;
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
        .eq(AssetsRepair.c_assetsId, assetID)
        .withConverter(AssetsRepair.converter);
    return data;
  }
}
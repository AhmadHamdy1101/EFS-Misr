import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/constants/constants.dart';

abstract class HomeRemoteDataSource {
  Future<List<Tickets>> getTickets();

  Future<List<Assets>> getAssets();

  Future<List<Users>> getUsers();
  Future<List<Assets>> getAssetsWithTicketID({required BigInt ticketId});

  Future<List<Tickets>> getTicketsWithAssetsID({required BigInt assetId});

  Future<Assets> getAssetsByQrCode(String qrCode);

  Future<List<AssetsRepair>> getAssetsRepairDetailsWithTicketId({
    required BigInt ticketID,
  });
  Future<List<AssetsRepair>> getAssetsRepairWithAssetId({
    required BigInt assetID,
  });
}

class HomeRemoteDataSourceImpl extends HomeRemoteDataSource {
  @override
  Future<List<Tickets>> getTickets() async {
    final tickets = await supabaseClient.tickets
        .select('''
      *,
      branch(*,area(*)),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
        .order('created_at', ascending: false)
        .withConverter(Tickets.converter);
    return tickets;
  }

  @override
  Future<List<Assets>> getAssets() async {
    final assets = await supabaseClient.assets
        .select('''
      *,
      branch(*,area(*))
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
  Future<List<Users>> getUsers() async {
    final users = await supabaseClient.users
        .select('*,positions(*)')
        .withConverter(Users.converter);
    return users;
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
  Future<List<Tickets>> getTicketsWithAssetsID({
    required BigInt assetId,
  }) async {
    final assetsAndTickets = await supabaseClient.tickets
        .select(
          '*, engineer:users!tickets_engineer_fkey(*,positions(*)), branch:branch(*),assets_tickets_details!inner(*)',
        )
        .eq('assets_tickets_details.assets_id', assetId)
        .withConverter(Tickets.converter);
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

import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/constants/constants.dart';

abstract class HomeRemoteDataSource {
  Future<List<Tickets>> getTickets();

  Future<List<Assets>> getAssets();

  Future<List<Users>> getUsers();
  Future<List<Assets>> getAssetsAndTickets({
    required BigInt ticketId
});

  Future<Assets> getAssetsByQrCode(String qrCode);
}

class HomeRemoteDataSourceImpl extends HomeRemoteDataSource {
  @override
  Future<List<Tickets>> getTickets() async {
    final tickets = await supabaseClient.tickets
        .select('''
      *,
      branch(*),
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
  Future<List<Users>> getUsers() async {
    final users = await supabaseClient.users
        .select('*,positions(*)')
        .withConverter(Users.converter);
    return users;
  }

  @override
  Future<List<Assets>> getAssetsAndTickets({required BigInt ticketId}) async{
    final assetsAndTickets = await supabaseClient.assets.select('*,branch(*), assets_tickets_details!inner(*)')
        .eq('assets_tickets_details.Tickets_id', ticketId).withConverter(Assets.converter);
    return assetsAndTickets;
  }
  
}

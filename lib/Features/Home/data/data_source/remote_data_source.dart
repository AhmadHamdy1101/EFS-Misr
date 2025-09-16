import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/constants/constants.dart';

abstract class HomeRemoteDataSource {
  Future<List<Tickets>> getTickets();

  Future<List<Assets>> getAssets();

  // Stream<List<Users>> getUsers();

  Future<Assets> getAssetsByQrCode(String qrCode);
}

class HomeRemoteDataSourceImpl extends HomeRemoteDataSource {
  @override
  Future<List<Tickets>> getTickets() async {
    final tickets = await supabaseClient.tickets
        .select('''
      *,
      branch(*)
    ''')
        .withConverter(Tickets.converter);
    return tickets;
  }

  @override
  Future<List<Assets>> getAssets() async {
    final assets = await supabaseClient.assets
        .select('''
      *,
      Branch(*),
      tickets(*)
    ''')
        .withConverter(Assets.converter);

    return assets;
  }

  @override
  Future<Assets> getAssetsByQrCode(String qrCode) async {
    final asset = await supabaseClient.assets
        .select('*,Branch(*),tickets(*)')
        .eq('barcode', qrCode)
        .withConverter(Assets.converter);
    return asset[0];
  }

  // @override
  // Stream<List<Users>> getUsers()  {
  //   return supabaseClient.users.stream(primaryKey: ['id'],).map((data) {
  //     return data.map((json) => Users.fromJson(json)).toList();
  //   });
  // }
}

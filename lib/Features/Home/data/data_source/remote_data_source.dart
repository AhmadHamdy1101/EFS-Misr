import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/constants/constants.dart';

abstract class HomeRemoteDataSource{
  Future<List<Tickets>> getTickets();
}
class HomeRemoteDataSourceImpl extends HomeRemoteDataSource{
  @override
  Future<List<Tickets>> getTickets() async{
   final tickets = await supabaseClient.tickets.select('''
      *,
      branch(*)
    ''').withConverter(Tickets.converter);
   return tickets;
  }

}
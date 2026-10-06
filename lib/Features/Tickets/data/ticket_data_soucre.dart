import '../../../constants/constants.dart';
import '../../../core/models/supadart_header.dart';
import '../../../core/models/tickets.dart';

abstract class TicketDataSource {
  Future<List<Tickets>> getTickets();
  Future<List<Tickets>> getTicketsWithAssetsID({required BigInt assetId});
}

class TicketDataSourceImpl extends TicketDataSource {
  @override
  Future<List<Tickets>> getTickets() async {
    final tickets = await supabaseClient.tickets
        .select('''
      *,
      branch(*,area:area!branch_area_fkey(*)),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
        .order('created_at', ascending: false)
        .withConverter(Tickets.converter);
    return tickets;
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
}
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/supadart_header.dart';
import '../../../core/models/tickets.dart';
import '../../../core/models/user.dart';
import '../domain/entities/ticket_entity.dart';
import 'models/ticket_change_model.dart';
import 'models/ticket_lookup_model.dart';

abstract interface class TicketDataSource {
  Future<List<Tickets>> getTickets();
  Future<Tickets?> getTicketById(BigInt ticketId);
  Future<List<Tickets>> getTicketsWithAssetsId(BigInt assetId);
  Future<Tickets> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  });
  Future<Tickets> updateTicketStatus({
    required BigInt ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  });
  Future<Tickets> updateDamageDescription({
    required BigInt ticketId,
    required String damageDescription,
  });
  Future<Tickets> updateTicketResponseDate({
    required BigInt ticketId,
    required DateTime responseDate,
  });
  Future<void> deleteTicket(BigInt ticketId);
  Future<List<TicketLookupModel>> getBranches();
  Future<List<TicketLookupModel>> getEngineers();
  Future<List<Users>> getUsersByIds(List<BigInt> ids);
  Stream<TicketChangeModel> watchTicketChanges();
}

class TicketDataSourceImpl implements TicketDataSource {
  TicketDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _ticketSelection = '''
    id,orecal_id,branch,request_date,repair_date,response_date,repair_duration,
    priority,engineer,closed_by,amount,damage_description,attachment,comment,
    status,variation,created_at,
    branch_details:branch(
      id,branch_id,name,area:area!branch_area_fkey(id,name)
    ),
    engineer_user:users!tickets_engineer_fkey(
      id,userid,name,email,address,phone,role,status,Company,company_email,image,
      positions(*)
    )
  ''';

  @override
  Future<List<Tickets>> getTickets() async {
    return _client.tickets
        .select(_ticketSelection)
        .order('created_at', ascending: false)
        .withConverter(Tickets.converter);
  }

  @override
  Future<Tickets?> getTicketById(BigInt ticketId) async {
    final rows = await _client.tickets
        .select(_ticketSelection)
        .eq('id', ticketId.toString())
        .limit(1)
        .withConverter(Tickets.converter);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<List<Tickets>> getTicketsWithAssetsId(BigInt assetId) async {
    return _client.tickets
        .select('$_ticketSelection, assets_tickets_details!inner(assets_id)')
        .eq('assets_tickets_details.assets_id', assetId.toString())
        .order('created_at', ascending: false)
        .withConverter(Tickets.converter);
  }

  @override
  Future<Tickets> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  }) async {
    return _client.tickets
        .insert(
          Tickets.insert(
            orecalId: oracleId,
            comment: comment,
            branch: branchId,
            priority: priority,
            requestDate: requestDate,
            engineer: engineerId,
          ),
        )
        .select(_ticketSelection)
        .single()
        .withConverter(Tickets.converterSingle);
  }

  @override
  Future<Tickets> updateTicketStatus({
    required BigInt ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  }) async {
    return _client.tickets
        .update(
          Tickets.update(
            status: status.databaseValue,
            repairDate: repairDate,
          ),
        )
        .eq('id', ticketId.toString())
        .select(_ticketSelection)
        .single()
        .withConverter(Tickets.converterSingle);
  }

  @override
  Future<Tickets> updateDamageDescription({
    required BigInt ticketId,
    required String damageDescription,
  }) async {
    return _client.tickets
        .update(Tickets.update(damageDescription: damageDescription))
        .eq('id', ticketId.toString())
        .select(_ticketSelection)
        .single()
        .withConverter(Tickets.converterSingle);
  }

  @override
  Future<Tickets> updateTicketResponseDate({
    required BigInt ticketId,
    required DateTime responseDate,
  }) async {
    return _client.tickets
        .update(Tickets.update(responseDate: responseDate))
        .eq('id', ticketId.toString())
        .select(_ticketSelection)
        .single()
        .withConverter(Tickets.converterSingle);
  }

  @override
  Future<void> deleteTicket(BigInt ticketId) async {
    await _client.tickets.delete().eq('id', ticketId.toString());
  }

  @override
  Future<List<TicketLookupModel>> getBranches() async {
    final rows = await _client.branch.select('id,name').order('name');
    return rows.map((row) => TicketLookupModel.fromJson(row)).toList();
  }

  @override
  Future<List<TicketLookupModel>> getEngineers() async {
    final rows = await _client.users
        .select('id,name')
        .eq('positions', 3)
        .order('name');
    return rows.map((row) => TicketLookupModel.fromJson(row)).toList();
  }

  @override
  Future<List<Users>> getUsersByIds(List<BigInt> ids) async {
    if (ids.isEmpty) return const [];
    return _client.users
        .select(
          'id,userid,name,email,phone,address,role,status,created_at,company_email,Company,image,positions(*)',
        )
        .inFilter('id', ids.map((id) => id.toString()).toList())
        .withConverter(Users.converter);
  }

  @override
  Stream<TicketChangeModel> watchTicketChanges() {
    final controller = StreamController<TicketChangeModel>();
    final channel = _client.channel(
      'public:tickets:${identityHashCode(controller)}',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            final deleted = payload.eventType == PostgresChangeEvent.delete;
            final record = deleted ? payload.oldRecord : payload.newRecord;
            final id = BigInt.tryParse(record['id']?.toString() ?? '');
            if (id != null && !controller.isClosed) {
              controller.add(TicketChangeModel(id: id, deleted: deleted));
            }
          },
        )
        .subscribe((status, error) {
          if (error != null && !controller.isClosed) {
            controller.addError(error);
          }
        });

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };
    return controller.stream;
  }
}

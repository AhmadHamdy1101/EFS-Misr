import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/supadart_header.dart';
import '../../../core/models/tickets.dart';
import '../../../core/paging/page_query.dart';
import '../domain/entities/ticket_entity.dart';
import '../domain/entities/ticket_stats.dart';
import 'models/ticket_change_model.dart';
import 'models/ticket_lookup_model.dart';

abstract interface class TicketDataSource {
  Future<List<Tickets>> getTickets(PageQuery query);
  Future<TicketStats> getTicketStats();
  Future<List<Map<String, dynamic>>> getExportRows();
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
    ),
    closed_by_user:users!tickets_closed_by_fkey(
      id,userid,name,email,address,phone,role,status,Company,company_email,image,
      positions(*)
    )
  ''';

  @override
  Future<List<Tickets>> getTickets(PageQuery query) async {
    // The area lives on the branch, so filtering by it needs an inner join
    // that drops tickets whose branch is in another area.
    final selection = query.areaId == null
        ? _ticketSelection
        : _ticketSelection.replaceFirst(
            'branch_details:branch(',
            'branch_details:branch!inner(',
          );
    var request = _client.tickets.select(selection);
    if (query.branchId != null) {
      request = request.eq(Tickets.c_branch, query.branchId!);
    }
    if (query.areaId != null) {
      request = request.eq('branch_details.area', query.areaId!);
    }
    if (query.hasSearch) request = request.or(_searchFilter(query.search));
    return request
        .order(Tickets.c_createdAt, ascending: false)
        .order(Tickets.c_id, ascending: false)
        .range(query.from, query.to)
        .withConverter(Tickets.converter);
  }

  /// Text columns are matched with ilike; the Oracle ID and status are
  /// matched exactly because ilike doesn't work on numbers or enums.
  String _searchFilter(String search) {
    final lower = search.toLowerCase();
    return [
      ilikeAny([Tickets.c_comment, Tickets.c_damageDescription], search),
      if (BigInt.tryParse(search) != null) '${Tickets.c_orecalId}.eq.$search',
      for (final status in TicketStatus.values)
        if (status != TicketStatus.unknown &&
            status.databaseValue.toLowerCase().startsWith(lower))
          '${Tickets.c_status}.eq.${status.databaseValue}',
    ].join(',');
  }

  @override
  Future<TicketStats> getTicketStats() async {
    final counts = await Future.wait([
      _client.tickets.count(),
      _client.tickets.count().eq(
        Tickets.c_status,
        TicketStatus.completed.databaseValue,
      ),
      _client.tickets.count().eq(
        Tickets.c_status,
        TicketStatus.awaiting.databaseValue,
      ),
    ]);
    return TicketStats(
      total: counts[0],
      completed: counts[1],
      awaiting: counts[2],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExportRows() async {
    final rows = await _client.tickets
        .select(
          'orecal_id,branch(name,branch_id),priority,request_date,repair_date,'
          'response_date,damage_description,status',
        )
        .order(Tickets.c_createdAt, ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
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
          Tickets.update(status: status.databaseValue, repairDate: repairDate),
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

import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Engineer → Technician hierarchy (`users.supervisor_id`, see
/// supabase/migrations/20261028130742_engineer_technician_hierarchy.sql).
///
/// Engineers are users with role `User`, technicians role `Worker`. Read on
/// its own, not through `Users.selectColumns`, so the rest of the app keeps
/// working on a database where the migration hasn't been applied yet; then
/// [TeamDirectory.available] is false and screens show no grouping.
class TeamDirectory {
  const TeamDirectory({
    required this.available,
    this.supervisorOf = const {},
    this.engineers = const {},
  });

  static const unavailable = TeamDirectory(available: false);

  final bool available;

  /// Technician id → engineer id (null: no engineer).
  final Map<BigInt, BigInt?> supervisorOf;

  /// Active engineers: id → name.
  final Map<BigInt, String> engineers;

  BigInt? engineerOf(BigInt technicianId) {
    final id = supervisorOf[technicianId];
    // A link to someone who is no longer an active engineer counts as none.
    return id != null && engineers.containsKey(id) ? id : null;
  }

  String? engineerNameOf(BigInt technicianId) =>
      engineers[engineerOf(technicianId)];

  List<BigInt> techniciansOf(BigInt engineerId) => [
    for (final e in supervisorOf.entries)
      if (e.value == engineerId && engineers.containsKey(engineerId)) e.key,
  ];

  /// Groups [items] (technicians) under their engineer, keeping the order
  /// of [items] inside each group. Groups are ordered by engineer name,
  /// [viewerId]'s own group first and technicians without an engineer last.
  List<TeamGroup<T>> group<T>(
    List<T> items,
    BigInt Function(T) idOf, {
    BigInt? viewerId,
  }) {
    final byEngineer = <BigInt?, List<T>>{};
    for (final item in items) {
      byEngineer.putIfAbsent(engineerOf(idOf(item)), () => []).add(item);
    }
    final groups = [
      for (final e in byEngineer.entries)
        TeamGroup<T>(
          engineerId: e.key,
          engineerName: engineers[e.key],
          members: e.value,
        ),
    ];
    int rank(TeamGroup<T> g) => g.engineerId == null
        ? 2
        : g.engineerId == viewerId
        ? 0
        : 1;
    groups.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return (a.engineerName ?? '').toLowerCase().compareTo(
        (b.engineerName ?? '').toLowerCase(),
      );
    });
    return groups;
  }

  /// Built from `users` rows with `id, name, role, status, supervisor_id`.
  factory TeamDirectory.fromRows(List<Map<String, dynamic>> rows) {
    final supervisorOf = <BigInt, BigInt?>{};
    final engineers = <BigInt, String>{};
    for (final row in rows) {
      final id = BigInt.tryParse('${row['id']}');
      if (id == null) continue;
      final status = int.tryParse('${row['status']}') ?? 0;
      final active = status != 3 && status != 4;
      switch (row['role']) {
        case 'User' when active:
          engineers[id] = row['name']?.toString() ?? '';
        case 'Worker':
          final raw = row['supervisor_id'];
          supervisorOf[id] = raw == null ? null : BigInt.tryParse('$raw');
      }
    }
    return TeamDirectory(
      available: true,
      supervisorOf: supervisorOf,
      engineers: engineers,
    );
  }
}

class TeamGroup<T> {
  const TeamGroup({
    required this.engineerId,
    required this.engineerName,
    required this.members,
  });

  /// Null for technicians without an engineer.
  final BigInt? engineerId;
  final String? engineerName;
  final List<T> members;
}

abstract interface class TeamRepo {
  /// Never throws: [TeamDirectory.unavailable] when it can't be read.
  Future<TeamDirectory> load();

  /// Admin only (enforced by the database). Null removes the engineer.
  Future<void> setSupervisor(BigInt technicianId, BigInt? engineerId);
}

class TeamRepoImpl implements TeamRepo {
  TeamRepoImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<TeamDirectory> load() async {
    try {
      final rows = await _client
          .from('users')
          .select('id,name,role,status,supervisor_id')
          .inFilter('role', ['User', 'Worker']);
      return TeamDirectory.fromRows(rows);
    } catch (error) {
      // 42703 (undefined column) until the migration is applied.
      developer.log('Team hierarchy unavailable: $error', name: 'TeamRepo');
      return TeamDirectory.unavailable;
    }
  }

  @override
  Future<void> setSupervisor(BigInt technicianId, BigInt? engineerId) async {
    final rows = await _client
        .from('users')
        .update({'supervisor_id': engineerId?.toString()})
        .eq('id', technicianId.toString())
        .select('id');
    // RLS hides rows the caller may not update instead of raising.
    if (rows.isEmpty) {
      throw const PostgrestException(message: 'Not allowed', code: '42501');
    }
  }
}

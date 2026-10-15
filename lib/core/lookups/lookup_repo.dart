import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Errors/failure.dart';

/// A row from one of the small reference tables (branch, area, positions).
class LookupOption {
  const LookupOption({required this.id, required this.name, this.areaId});

  final BigInt id;
  final String name;

  /// The area a branch belongs to; null for other tables.
  final BigInt? areaId;
}

extension LookupOptionsDropdown on List<LookupOption> {
  /// Shape expected by `CustomDropdownWidget.data`.
  List<Map<String, dynamic>> toDropdownData() => [
    for (final option in this)
      {'name': option.name, 'value': option.id.toString()},
  ];
}

abstract interface class LookupRepo {
  Future<Either<Failure, List<LookupOption>>> getBranches();
  Future<Either<Failure, List<LookupOption>>> getAreas();
  Future<Either<Failure, List<LookupOption>>> getPositions();

  /// Drops cached rows so the next call refetches (e.g. on sign-out).
  void clearCache();
}

/// Reference tables rarely change, so each one is fetched once per session
/// and shared by every screen that needs it.
class LookupRepoImpl implements LookupRepo {
  LookupRepoImpl(this._client);

  final SupabaseClient _client;
  final Map<String, Future<List<LookupOption>>> _cache = {};

  @override
  Future<Either<Failure, List<LookupOption>>> getBranches() => _load('branch');

  @override
  Future<Either<Failure, List<LookupOption>>> getAreas() => _load('area');

  @override
  Future<Either<Failure, List<LookupOption>>> getPositions() =>
      _load('positions');

  @override
  void clearCache() => _cache.clear();

  Future<Either<Failure, List<LookupOption>>> _load(String table) async {
    final future = _cache.putIfAbsent(table, () => _fetch(table));
    try {
      return Right(await future);
    } catch (error) {
      _cache.remove(table);
      return Left(Failure.fromException(error));
    }
  }

  Future<List<LookupOption>> _fetch(String table) async {
    final columns = table == 'branch' ? 'id,name,area' : 'id,name';
    final rows = await _client.from(table).select(columns).order('name');
    return List.unmodifiable(
      rows.map(
        (row) => LookupOption(
          id: BigInt.parse(row['id'].toString()),
          name: row['name']?.toString() ?? '',
          areaId: BigInt.tryParse(row['area']?.toString() ?? ''),
        ),
      ),
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Assets_data/domain/asset_code.dart';
import 'package:efs_misr/Features/Assets_data/domain/entities/assets_entity.dart';
import 'package:efs_misr/Features/Assets_data/domain/repo/assets_data_repo.dart';
import 'package:efs_misr/Features/Assets_data/presentation/controller/assets_cubit.dart';
import 'package:efs_misr/Features/Notifications/data/firebase_push_service.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_worker.dart';
import 'package:efs_misr/Features/Tracking/presentation/controller/tracking_control_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/auth/app_permissions.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/team/team.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(int id, String role, {int status = 1, String? name}) =>
    UserEntity(
      id: BigInt.from(id),
      userid: 'uid-$id',
      name: name ?? 'U$id',
      email: '$id@efs.com',
      phone: '',
      address: '',
      role: role,
      status: status,
      position: null,
      companyEmail: '',
      company: 'EFS',
      image: '',
    );

Map<String, dynamic> _row(
  int id,
  String role, {
  int status = 1,
  int? supervisor,
  String? name,
}) => {
  'id': id,
  'name': name ?? 'U$id',
  'role': role,
  'status': status,
  'supervisor_id': supervisor,
};

/// Records repo calls; anything else is unexpected.
class _RecordingAssetsRepo implements AssetsDataRepo {
  final calls = <String>[];

  @override
  Future<Either<Failure, AssetsEntity>> updateAsset({
    required int id,
    required String barcode,
    required String name,
    required String floor,
    required String place,
    required String? type,
    required BigInt branch,
  }) async {
    calls.add('update $id');
    return Left(GeneralFailure('server'));
  }

  @override
  Future<Either<Failure, Unit>> deleteAsset(int id) async {
    calls.add('delete $id');
    return Left(GeneralFailure('server'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TeamDirectory (engineer → technician)', () {
    final team = TeamDirectory.fromRows([
      _row(1, 'User', name: 'Omar'),
      _row(2, 'User', name: 'Ahmed'),
      _row(3, 'User', name: 'Suspended Eng', status: 4),
      _row(10, 'Worker', supervisor: 1),
      _row(11, 'Worker', supervisor: 2),
      _row(12, 'Worker', supervisor: 1),
      _row(13, 'Worker'), // unassigned
      _row(14, 'Worker', supervisor: 3), // engineer suspended
      _row(15, 'Worker', supervisor: 99), // engineer gone
      _row(20, 'Admin'),
    ]);

    test('reads the persisted links; admins are neither side', () {
      expect(team.available, isTrue);
      expect(team.engineers.keys, unorderedEquals([BigInt.one, BigInt.two]));
      expect(team.engineerOf(BigInt.from(10)), BigInt.one);
      expect(team.engineerNameOf(BigInt.from(11)), 'Ahmed');
      expect(team.supervisorOf.containsKey(BigInt.from(20)), isFalse);
    });

    test('missing, suspended or deleted engineer counts as unassigned', () {
      expect(team.engineerOf(BigInt.from(13)), isNull);
      expect(team.engineerOf(BigInt.from(14)), isNull);
      expect(team.engineerOf(BigInt.from(15)), isNull);
    });

    test('techniciansOf lists only that engineer\'s technicians', () {
      expect(
        team.techniciansOf(BigInt.one),
        unorderedEquals([BigInt.from(10), BigInt.from(12)]),
      );
      expect(team.techniciansOf(BigInt.from(3)), isEmpty);
    });

    test('groups by engineer name, unassigned last, order kept', () {
      final ids = [10, 11, 12, 13, 14].map(BigInt.from).toList();
      final groups = team.group(ids, (id) => id);
      expect(groups.map((g) => g.engineerName), ['Ahmed', 'Omar', null]);
      expect(groups[1].members, [BigInt.from(10), BigInt.from(12)]);
      expect(groups[2].members, [BigInt.from(13), BigInt.from(14)]);
    });

    test("the viewing engineer's own group comes first", () {
      final ids = [10, 11].map(BigInt.from).toList();
      final groups = team.group(ids, (id) => id, viewerId: BigInt.one);
      expect(groups.first.engineerName, 'Omar');
    });

    test('engineers without technicians produce no group', () {
      final groups = team.group([BigInt.from(13)], (id) => id);
      expect(groups, hasLength(1));
      expect(groups.single.engineerId, isNull);
    });

    test('unavailable (column missing) reports nothing', () {
      const none = TeamDirectory.unavailable;
      expect(none.available, isFalse);
      expect(none.engineerOf(BigInt.from(10)), isNull);
    });
  });

  group('tracking list grouping', () {
    final workers = [_user(10, 'Worker'), _user(13, 'Worker')];
    TrackingControlState state(TeamDirectory team) => TrackingControlState(
      now: DateTime(2026, 10, 28),
      workers: workers,
      team: team,
    );

    test('no grouping before the migration or when nobody is assigned', () {
      expect(state(TeamDirectory.unavailable).visibleGroups(), isNull);
      final nobody = TeamDirectory.fromRows([
        _row(1, 'User'),
        _row(10, 'Worker'),
      ]);
      expect(state(nobody).visibleGroups(), isNull);
    });

    test('groups visible workers under their engineer', () {
      final team = TeamDirectory.fromRows([
        _row(1, 'User', name: 'Omar'),
        _row(10, 'Worker', supervisor: 1),
        _row(13, 'Worker'),
      ]);
      final groups = state(team).visibleGroups()!;
      expect(groups.map((g) => g.engineerName), ['Omar', null]);
      expect(groups.first.members.map((TrackingWorker w) => w.user.id), [
        BigInt.from(10),
      ]);
    });
  });

  group('asset QR code', () {
    test('trims spaces, line breaks and control characters', () {
      expect(normalizeAssetCode('  EFS-001\r\n'), 'EFS-001');
      expect(normalizeAssetCode('\u0000EFS-001\t'), 'EFS-001');
    });

    test('keeps inner characters exactly (case, dashes)', () {
      expect(normalizeAssetCode('Efs 01-a'), 'Efs 01-a');
    });

    test('rejects empty or oversized values', () {
      expect(normalizeAssetCode(''), isNull);
      expect(normalizeAssetCode(' \n '), isNull);
      expect(normalizeAssetCode('x' * (maxAssetCodeLength + 1)), isNull);
      expect(normalizeAssetCode('x' * maxAssetCodeLength), isNotNull);
    });
  });

  group('admin-only asset edit / delete', () {
    test('only admins may edit or delete assets', () {
      for (final (role, allowed) in [
        ('Admin', true),
        ('User', false),
        ('Worker', false),
      ]) {
        final p = AppPermissions(_user(1, role));
        expect(p.canEditAsset, allowed, reason: role);
        expect(p.canDeleteAsset, allowed, reason: role);
      }
      final suspendedAdmin = AppPermissions(_user(1, 'Admin', status: 3));
      expect(suspendedAdmin.canEditAsset, isFalse);
      expect(suspendedAdmin.canDeleteAsset, isFalse);
    });

    test('the cubit refuses non-admins without calling the server', () async {
      for (final role in ['User', 'Worker']) {
        final repo = _RecordingAssetsRepo();
        final cubit = AssetsCubit(
          repo,
          permissions: () => AppPermissions(_user(2, role)),
        );
        final update = await cubit.updateAsset(
          id: 5,
          barcode: 'A',
          name: '',
          floor: '',
          place: '',
          type: null,
          branch: BigInt.one,
        );
        final delete = await cubit.deleteAsset(5);
        expect(update.isLeft(), isTrue);
        expect(delete.isLeft(), isTrue);
        expect(repo.calls, isEmpty, reason: role);
        await cubit.close();
      }
    });

    test('admins reach the server, and its refusal is returned', () async {
      final repo = _RecordingAssetsRepo();
      final cubit = AssetsCubit(
        repo,
        permissions: () => AppPermissions(_user(1, 'Admin')),
      );
      final delete = await cubit.deleteAsset(5);
      expect(repo.calls, ['delete 5']);
      expect(delete.fold((f) => f.message, (_) => ''), 'server');
      await cubit.close();
    });
  });

  group('web push click link', () {
    setUp(FirebasePushService.resetWebLaunch);

    test('reads the ids send-push put in the link, once', () {
      final uri = Uri.parse(
        'https://app.example/?efs_push=42&type=ticket.assigned&ticket_id=7',
      );
      expect(FirebasePushService.webLaunchData(uri), {
        'notification_id': '42',
        'type': 'ticket.assigned',
        'ticket_id': '7',
      });
      expect(FirebasePushService.webLaunchData(uri), isNull);
    });

    test('ignores ordinary page loads', () {
      expect(
        FirebasePushService.webLaunchData(Uri.parse('https://app.example/')),
        isNull,
      );
    });
  });
}

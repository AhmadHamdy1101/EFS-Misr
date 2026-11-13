import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/Features/Tickets/presentation/controller/tickets_cubit.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/auth/app_permissions.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

UserEntity _user(int id, String role, {int status = 1}) => UserEntity(
  id: BigInt.from(id),
  userid: 'uid-$id',
  name: 'U$id',
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

final admin = AppPermissions(_user(1, 'Admin'));
final viewer = AppPermissions(_user(2, 'User'));
final tech = AppPermissions(_user(3, 'Worker'));
final suspended = AppPermissions(_user(4, 'Worker', status: 4));

void main() {
  group('role mapping', () {
    test('database roles map to app roles', () {
      expect(admin.role, AppRole.admin);
      expect(viewer.role, AppRole.user);
      expect(tech.role, AppRole.technician);
      expect(suspended.role, AppRole.none);
      expect(AppPermissions(_user(5, 'Something')).role, AppRole.none);
      expect(AppPermissions(null).role, AppRole.none);
    });
  });

  group('permission matrix', () {
    // engineer 3 = the technician; engineer 9 = someone else.
    const own = 3;
    const others = 9;

    test('create / delete tickets and assets, manage accounts: admin only', () {
      for (final p in [admin, viewer, tech, suspended]) {
        final isAdmin = p == admin;
        expect(p.canCreateTicket, isAdmin);
        expect(p.canDeleteTicket, isAdmin);
        expect(p.canCreateAsset, isAdmin);
        expect(p.canManageAccounts, isAdmin);
      }
    });

    test('maintenance work: admin on any ticket, technician on own only', () {
      expect(admin.canWorkOn(others), isTrue);
      expect(tech.canWorkOn(own), isTrue);
      expect(tech.canWorkOn(others), isFalse);
      expect(tech.canWorkOn(null), isFalse);
      expect(viewer.canWorkOn(own), isFalse);
      expect(suspended.canWorkOn(4), isFalse);
    });

    test('status changes', () {
      expect(admin.statusChangesFor(TicketStatus.awaiting, others), [
        TicketStatus.canceled,
        TicketStatus.completed,
      ]);
      expect(tech.statusChangesFor(TicketStatus.awaiting, own), [
        TicketStatus.rejected,
        TicketStatus.completed,
      ]);
      expect(tech.statusChangesFor(TicketStatus.awaiting, others), isEmpty);
      expect(tech.statusChangesFor(TicketStatus.completed, own), isEmpty);
      expect(viewer.statusChangesFor(TicketStatus.awaiting, own), isEmpty);
      expect(
        tech.canSetStatus(TicketStatus.awaiting, TicketStatus.canceled, own),
        isFalse,
      );
    });

    test('live tracking', () {
      expect(admin.canViewTracking, isTrue);
      expect(admin.canControlTracking, isTrue);
      expect(admin.canShareLocation, isFalse);
      expect(viewer.canViewTracking, isTrue);
      expect(viewer.canControlTracking, isFalse);
      expect(viewer.canShareLocation, isFalse);
      expect(tech.canViewTracking, isFalse);
      expect(tech.canControlTracking, isFalse);
      expect(tech.canShareLocation, isTrue);
      expect(suspended.canShareLocation, isFalse);
    });
  });

  group('TicketsCubit refuses before calling the server', () {
    late _CountingRepo repo;

    TicketsCubit cubitFor(AppPermissions permissions) =>
        TicketsCubit(ticketsRepo: repo, permissions: () => permissions);

    setUp(() => repo = _CountingRepo());

    test('a user cannot create a ticket', () async {
      final cubit = cubitFor(viewer);
      final result = await cubit.addTicket(
        oracleId: BigInt.one,
        comment: 'x',
        branchId: BigInt.one,
        priority: 'A',
        requestDate: DateTime(2026),
        engineerId: BigInt.one,
      );
      expect(result.isLeft(), isTrue);
      expect(repo.calls, isEmpty);
      await cubit.close();
    });

    test('a technician cannot delete a ticket', () async {
      final cubit = cubitFor(tech);
      final result = await cubit.deleteTicket(ticketId: 1);
      expect(result.isLeft(), isTrue);
      expect(repo.calls, isEmpty);
      await cubit.close();
    });

    test('an admin can delete a ticket', () async {
      final cubit = cubitFor(admin);
      final result = await cubit.deleteTicket(ticketId: 1);
      expect(result.isRight(), isTrue);
      expect(repo.calls, ['delete']);
      await cubit.close();
    });
  });
}

class _CountingRepo implements TicketsRepo {
  final calls = <String>[];

  @override
  Future<Either<Failure, Unit>> deleteTicket({required BigInt ticketId}) async {
    calls.add('delete');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, TicketEntity>> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  }) async {
    calls.add('add');
    return Left(GeneralFailure('not used'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

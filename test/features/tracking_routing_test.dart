import 'package:efs_misr/Features/Notifications/domain/entities/app_notification.dart';
import 'package:efs_misr/core/auth/app_permissions.dart';
import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

AppPermissions _as(String role) => AppPermissions(
  UserEntity(
    id: BigInt.one,
    userid: 'u',
    name: 'n',
    email: 'e',
    phone: '',
    address: '',
    role: role,
    status: 1,
    position: null,
    companyEmail: '',
    company: '',
    image: '',
  ),
);

void main() {
  group('location request notifications', () {
    test('a request opens the consent screen with its request id', () {
      final target = NotificationTarget.fromData('tracking.requested', {
        'request_id': 'r-1',
        'technician_id': '44',
      });
      expect(target, isA<MyLocationTarget>());
      expect((target as MyLocationTarget).requestId, 'r-1');
    });

    test('withdrawn / stopped open the same screen without a stale check', () {
      for (final type in ['tracking.cancelled', 'tracking.stopped']) {
        final target = NotificationTarget.fromData(type, {'request_id': 'r'});
        expect((target as MyLocationTarget).requestId, isNull, reason: type);
      }
    });

    test('answers go to the live view of that technician, never a ticket', () {
      final target = NotificationTarget.fromData('tracking.accepted', {
        'request_id': 'r-1',
        'technician_id': '44',
        'ticket_id': '60', // legacy rows may still carry one
      });
      expect(target, isA<WorkerTrackingTarget>());
      expect((target as WorkerTrackingTarget).technicianId, BigInt.from(44));
    });

    test('ticket notifications still open the ticket', () {
      final target = NotificationTarget.fromData('ticket.assigned', {
        'ticket_id': '60',
      });
      expect((target as TicketTarget).ticketId, 60);
    });
  });

  group('who may open what (router rules)', () {
    test('only technicians open the consent screen', () {
      expect(_as('Worker').canShareLocation, isTrue);
      expect(_as('Admin').canShareLocation, isFalse);
      expect(_as('User').canShareLocation, isFalse);
    });

    test('admins and engineers open the live view; engineers read-only', () {
      expect(_as('Admin').canViewTracking, isTrue);
      expect(_as('Admin').canControlTracking, isTrue);
      expect(_as('User').canViewTracking, isTrue);
      expect(_as('User').canControlTracking, isFalse);
      expect(_as('Worker').canViewTracking, isFalse);
    });
  });
}

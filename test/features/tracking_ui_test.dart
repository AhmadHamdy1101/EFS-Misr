import 'package:efs_misr/Features/Tracking/domain/entities/tracking_session.dart';
import 'package:efs_misr/Features/Tracking/domain/entities/tracking_worker.dart';
import 'package:efs_misr/Features/Tracking/presentation/widgets/tracking_widgets.dart';
import 'package:efs_misr/Features/Tracking/presentation/widgets/worker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'tracking_fakes.dart';

Widget _host(Widget child, {Size size = const Size(320, 640)}) =>
    GetMaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: size.width, child: child),
          ),
        ),
      ),
    );

void main() {
  final now = epoch.add(const Duration(minutes: 1));

  TrackingWorker live() => TrackingWorker(
    user: worker(1, 'Mohamed Abdelrahman Mostafa Elsayed'),
    session: session(10, technician: 1, lastLocationAt: now),
  );
  TrackingWorker idle() => TrackingWorker(user: worker(2, 'Ahmed Hassan'));

  group('WorkerTile', () {
    testWidgets('admin sees Request for a worker who is not sharing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          WorkerTile(
            worker: idle(),
            now: now,
            onView: () {},
            onRequest: () {},
            onCancelPending: () {},
          ),
        ),
      );
      expect(find.text('Request'), findsOneWidget);
    });

    testWidgets('read-only (User role) hides Request', (tester) async {
      await tester.pumpWidget(
        _host(
          WorkerTile(
            worker: idle(),
            now: now,
            readOnly: true,
            onView: () {},
            onRequest: () {},
            onCancelPending: () {},
          ),
        ),
      );
      expect(find.text('Request'), findsNothing);
    });

    testWidgets('read-only still offers View for a live worker', (
      tester,
    ) async {
      var viewed = false;
      await tester.pumpWidget(
        _host(
          WorkerTile(
            worker: live(),
            now: now,
            readOnly: true,
            onView: () => viewed = true,
            onRequest: () {},
            onCancelPending: () {},
          ),
        ),
      );
      await tester.tap(find.text('View'));
      expect(viewed, isTrue);
    });

    testWidgets('long names fit a 320 dp phone without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          WorkerTile(
            worker: live(),
            now: now,
            onView: () {},
            onRequest: () {},
            onCancelPending: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('stat cards fit three across on a 320 dp phone', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            Expanded(
              child: TrackingStatCard(
                icon: Icons.groups,
                value: 128,
                label: 'Total workers',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TrackingStatCard(
                icon: Icons.my_location,
                value: 12,
                label: 'Live now',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TrackingStatCard(
                icon: Icons.location_off,
                value: 116,
                label: 'Not sharing',
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('coordinates', () {
    TrackingSession at(double? lat, double? lng) => TrackingSession(
      id: 's',
      workerUid: 'u',
      technicianId: BigInt.one,
      status: TrackingStatus.active,
      latitude: lat,
      longitude: lng,
    );

    test('only valid positions count as a location', () {
      expect(at(30.05, 31.24).hasLocation, isTrue);
      expect(at(null, 31.24).hasLocation, isFalse);
      expect(at(0, 0).hasLocation, isFalse);
      expect(at(91, 31).hasLocation, isFalse);
      expect(at(30, 181).hasLocation, isFalse);
      expect(at(double.nan, 31).hasLocation, isFalse);
    });
  });
}

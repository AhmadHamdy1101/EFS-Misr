import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_worker.dart';
import '../controller/tracking_control_cubit.dart';
import '../widgets/request_location_dialog.dart';
import '../widgets/tracking_map.dart';
import '../widgets/tracking_widgets.dart';

/// Admin view of one worker: live map, destination branch, freshness and
/// accuracy, with call and stop actions. Updates come from the shared
/// [TrackingControlCubit], so this page opens no extra realtime channel.
class WorkerTrackingPage extends StatefulWidget {
  const WorkerTrackingPage({
    super.key,
    required this.technicianId,
    this.ticketId,
    this.ticketLabel,
  });

  final BigInt technicianId;

  /// Set when opened from a ticket, so a new request is tied to it.
  final int? ticketId;
  final String? ticketLabel;

  @override
  State<WorkerTrackingPage> createState() => _WorkerTrackingPageState();
}

class _WorkerTrackingPageState extends State<WorkerTrackingPage> {
  final _mapController = MapController();
  BranchLocation? _branch;
  int? _branchId;
  bool _mapReady = false;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<TrackingControlCubit>().state;
    _loadBranch(state.sessions[widget.technicianId]?.branchId);
  }

  void _loadBranch(int? branchId) {
    if (branchId == _branchId) return;
    _branchId = branchId;
    _branch = null;
    if (branchId == null) return;
    context.read<TrackingControlCubit>().branch(branchId).then((result) {
      if (!mounted || _branchId != branchId) return;
      setState(() => _branch = result.getOrElse(() => null));
    });
  }

  void _follow(TrackingSession? session) {
    if (!_mapReady || session == null || !session.hasLocation) return;
    _mapController.move(
      LatLng(session.latitude!, session.longitude!),
      _mapController.camera.zoom,
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && mounted) {
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        'Could not start the call.'.tr,
        isError: true,
      );
    }
  }

  Future<void> _stop(TrackingWorker worker) async {
    final session = worker.session;
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Stop tracking'.tr),
        content: Text(
          '${'Stop tracking'.tr} ${worker.user.name}? '
          '${'Their location will no longer be shared.'.tr}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Stop tracking'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _stopping = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<TrackingControlCubit>().cancel(session);
    if (!mounted) return;
    setState(() => _stopping = false);
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) => showAppSnackBar(messenger, 'Tracking stopped.'.tr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingControlCubit, TrackingControlState>(
      listenWhen: (previous, current) =>
          previous.sessions[widget.technicianId] !=
          current.sessions[widget.technicianId],
      listener: (context, state) {
        final session = state.sessions[widget.technicianId];
        _loadBranch(session?.branchId);
        _follow(session);
      },
      builder: (context, state) {
        final worker = state.workerById(widget.technicianId);
        if (worker == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: AppColors.green),
            body: Center(child: Text('Worker not found'.tr)),
          );
        }
        final session = worker.session;
        final trackingState = worker.stateAt(state.now);
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.black87,
            title: Text(worker.user.name, style: const TextStyle(fontSize: 26)),
          ),
          body: Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.36,
                child: _map(session, trackingState),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                  children: [
                    _profile(worker, trackingState),
                    const SizedBox(height: 30),
                    ..._details(session, trackingState, state.now),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: _actions(worker, trackingState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _map(TrackingSession? session, WorkerTrackingState trackingState) {
    final branch = _branch;
    final position = session != null && session.hasLocation
        ? LatLng(session.latitude!, session.longitude!)
        : null;
    final branchPoint = branch != null && branch.hasCoordinates
        ? LatLng(branch.latitude!, branch.longitude!)
        : null;
    return TrackingMap(
      controller: _mapController,
      initialCenter: position ?? branchPoint ?? defaultMapCenter,
      initialZoom: position != null ? 16 : 11,
      showZoomButtons: false,
      markers: [
        if (branchPoint != null)
          Marker(
            point: branchPoint,
            width: 44,
            height: 44,
            child: const BranchMarker(),
          ),
        if (position != null)
          Marker(
            point: position,
            width: 72,
            height: 72,
            child: WorkerMarker(
              size: 72,
              live: trackingState == WorkerTrackingState.live,
            ),
          ),
      ],
      onMapReady: () => _mapReady = true,
    );
  }

  Widget _profile(TrackingWorker worker, WorkerTrackingState trackingState) {
    final user = worker.user;
    return Row(
      children: [
        WorkerAvatar(user: user, radius: 42),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (user.position?.name ?? user.role).tr,
                style: const TextStyle(color: AppColors.gray, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TrackingStatusChip(state: trackingState),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _details(
    TrackingSession? session,
    WorkerTrackingState trackingState,
    DateTime now,
  ) {
    if (session == null) {
      return [
        TrackingInfoRow(
          icon: Icons.location_off_outlined,
          iconColor: AppColors.gray,
          title: 'Not sharing location'.tr,
          subtitle: 'Send a request to see where this worker is.'.tr,
        ),
      ];
    }
    if (session.status == TrackingStatus.pending) {
      return [
        TrackingInfoRow(
          icon: Icons.hourglass_top,
          iconColor: const Color(0xff2563EB),
          title: 'Waiting for approval'.tr,
          subtitle: 'The location appears once the worker accepts.'.tr,
        ),
      ];
    }

    final branch = _branch;
    final rows = <(String, String)>[];
    if (branch != null) rows.add(('Destination branch', branch.name));
    if (session.hasLocation) {
      if (branch != null && branch.hasCoordinates) {
        rows.add((
          'Distance to branch',
          formatDistance(
            distanceInMeters(
              session.latitude!,
              session.longitude!,
              branch.latitude!,
              branch.longitude!,
            ),
          ),
        ));
      }
      rows.add((
        'GPS coordinates',
        formatCoordinates(session.latitude!, session.longitude!),
      ));
    }
    rows.add(('Last successful update', timeAgo(session.lastLocationAt, now)));
    if (session.accuracy != null) {
      rows.add((
        'Location accuracy',
        '± ${session.accuracy!.round()} ${'meters'.tr}',
      ));
    }
    if (session.arrivedAt != null) {
      rows.add((
        'Arrived at branch',
        DateFormat('hh:mm a').format(session.arrivedAt!),
      ));
    }

    return [
      if (trackingState == WorkerTrackingState.offline) ...[
        TrackingInfoRow(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xffD97706),
          title: 'Location is out of date'.tr,
          subtitle:
              'No update recently. The worker may be offline, out of GPS '
                      'range, or the app was closed.'
                  .tr,
        ),
        const SizedBox(height: 20),
      ],
      if (branch != null && !branch.hasCoordinates) ...[
        TrackingInfoRow(
          icon: Icons.info_outline,
          iconColor: AppColors.gray,
          title: 'Branch location not set'.tr,
          subtitle: 'Add the branch coordinates to show distance.'.tr,
        ),
        const SizedBox(height: 20),
      ],
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.tr,
                  style: const TextStyle(color: AppColors.gray, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _actions(TrackingWorker worker, WorkerTrackingState trackingState) {
    final phone = worker.user.phone.trim();
    final callButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green, width: 2),
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(60),
        textStyle: const TextStyle(fontSize: 19),
      ),
      onPressed: phone.isEmpty ? null : () => _call(phone),
      icon: const Icon(Icons.phone),
      label: Text('Call worker'.tr),
    );
    final Widget mainButton;
    if (trackingState == WorkerTrackingState.notSharing) {
      mainButton = FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontSize: 19),
        ),
        onPressed: () => RequestLocationDialog.show(
          context,
          worker: worker,
          ticketId: widget.ticketId,
          ticketLabel: widget.ticketLabel,
        ),
        child: Text('Request location'.tr),
      );
    } else {
      final pending = trackingState == WorkerTrackingState.pending;
      mainButton = FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontSize: 19),
        ),
        onPressed: _stopping ? null : () => _stop(worker),
        child: Text(pending ? 'Cancel request'.tr : 'Stop tracking'.tr),
      );
    }
    return Row(
      children: [
        Expanded(child: callButton),
        const SizedBox(width: 22),
        Expanded(child: mainButton),
      ],
    );
  }
}

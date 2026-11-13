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

/// One worker: live map, destination branch, freshness and accuracy. Admins
/// can call, request and stop; with [readOnly] (role User) only call.
/// Updates come from the shared [TrackingControlCubit], so this page opens no
/// extra realtime channel.
class WorkerTrackingPage extends StatefulWidget {
  const WorkerTrackingPage({
    super.key,
    required this.technicianId,
    this.readOnly = false,
  });

  final BigInt technicianId;

  final bool readOnly;

  @override
  State<WorkerTrackingPage> createState() => _WorkerTrackingPageState();
}

class _WorkerTrackingPageState extends State<WorkerTrackingPage> {
  final _mapController = MapController();
  BranchLocation? _branch;
  int? _branchId;
  bool _mapReady = false;
  bool _stopping = false;

  /// The camera follows the worker until the user moves the map; the
  /// recenter button turns following back on.
  bool _following = true;

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

  void _follow(TrackingSession? session, {bool force = false}) {
    if (!_mapReady || session == null || !session.hasLocation) return;
    if (!_following && !force) return;
    _mapController.move(
      LatLng(session.latitude!, session.longitude!),
      force ? 16 : _mapController.camera.zoom,
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
        final sizes = TrackingSizes.of(context);
        final worker = state.workerById(widget.technicianId);
        if (worker == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            body: TrackingMessage(
              icon: Icons.person_off_outlined,
              text: 'Worker not found'.tr,
            ),
          );
        }
        final session = worker.session;
        final trackingState = worker.stateAt(state.now);
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final screenHeight = MediaQuery.sizeOf(context).height;
        final details = ListView(
          padding: EdgeInsets.all(sizes.gutter + 4),
          children: [
            _profile(worker, trackingState, sizes),
            SizedBox(height: sizes.compact ? 16 : 20),
            ..._details(session, trackingState, state.now, sizes),
          ],
        );
        final map = _map(session, trackingState, sizes);

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            title: Text(
              worker.user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: landscape
                    ? Row(
                        children: [
                          Expanded(child: map),
                          SizedBox(width: 380, child: details),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: (screenHeight * 0.36).clamp(200.0, 380.0),
                            child: map,
                          ),
                          Expanded(child: details),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sizes.gutter + 4,
                    8,
                    sizes.gutter + 4,
                    12,
                  ),
                  child: _actions(worker, trackingState, sizes),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _map(
    TrackingSession? session,
    WorkerTrackingState trackingState,
    TrackingSizes sizes,
  ) {
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
      onMapReady: () => _mapReady = true,
      onUserMoved: () => _following = false,
      onRecenter: position == null
          ? null
          : () {
              _following = true;
              _follow(session, force: true);
            },
      markers: [
        if (branchPoint != null)
          Marker(
            point: branchPoint,
            width: 40,
            height: 40,
            child: const BranchMarker(),
          ),
        if (position != null)
          Marker(
            key: ValueKey(widget.technicianId),
            point: position,
            width: sizes.marker + 8,
            height: sizes.marker + 8,
            child: WorkerMarker(
              size: sizes.marker + 8,
              live: trackingState == WorkerTrackingState.live,
            ),
          ),
      ],
    );
  }

  Widget _profile(
    TrackingWorker worker,
    WorkerTrackingState trackingState,
    TrackingSizes sizes,
  ) {
    final user = worker.user;
    return Row(
      children: [
        WorkerAvatar(user: user, radius: sizes.avatar + 4),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: sizes.title + 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (user.position?.name ?? user.role).tr,
                style: TextStyle(color: AppColors.gray, fontSize: sizes.body),
              ),
              const SizedBox(height: 6),
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
    TrackingSizes sizes,
  ) {
    if (session == null) {
      return [
        TrackingInfoRow(
          icon: Icons.location_off_outlined,
          iconColor: AppColors.gray,
          title: 'Not sharing location'.tr,
          subtitle: widget.readOnly
              ? 'This worker is not sharing their location right now.'.tr
              : 'Send a request to see where this worker is.'.tr,
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
      if (!session.hasLocation) ...[
        TrackingInfoRow(
          icon: Icons.gps_not_fixed,
          iconColor: const Color(0xffB45309),
          title: 'Waiting for the first location'.tr,
          subtitle: 'Sharing is on, but no valid position has arrived yet.'.tr,
        ),
        const SizedBox(height: 16),
      ] else if (trackingState == WorkerTrackingState.offline) ...[
        TrackingInfoRow(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xffB45309),
          title: 'Location is out of date'.tr,
          subtitle:
              'No update recently. The worker may be offline, out of GPS '
                      'range, or the app was closed.'
                  .tr,
        ),
        const SizedBox(height: 16),
      ],
      if (branch != null && !branch.hasCoordinates) ...[
        TrackingInfoRow(
          icon: Icons.info_outline,
          iconColor: AppColors.gray,
          title: 'Branch location not set'.tr,
          subtitle: 'Add the branch coordinates to show distance.'.tr,
        ),
        const SizedBox(height: 16),
      ],
      for (final (label, value) in rows)
        Padding(
          padding: EdgeInsets.only(bottom: sizes.compact ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label.tr,
                  style: TextStyle(color: AppColors.gray, fontSize: sizes.body),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: sizes.body,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _actions(
    TrackingWorker worker,
    WorkerTrackingState trackingState,
    TrackingSizes sizes,
  ) {
    final phone = worker.user.phone.trim();
    final buttonSize = Size.fromHeight(sizes.buttonHeight);
    final textStyle = TextStyle(
      fontSize: sizes.compact ? 14 : 15,
      fontWeight: FontWeight.w600,
    );
    final callButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green, width: 1.5),
        shape: const StadiumBorder(),
        minimumSize: buttonSize,
        textStyle: textStyle,
      ),
      onPressed: phone.isEmpty ? null : () => _call(phone),
      icon: const Icon(Icons.phone, size: 20),
      label: Text('Call worker'.tr),
    );
    if (widget.readOnly) return callButton;

    final mainStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.green,
      shape: const StadiumBorder(),
      minimumSize: buttonSize,
      textStyle: textStyle,
    );
    final Widget mainButton = trackingState == WorkerTrackingState.notSharing
        ? FilledButton(
            style: mainStyle,
            onPressed: () =>
                RequestLocationDialog.show(context, worker: worker),
            child: Text('Request location'.tr),
          )
        : FilledButton(
            style: mainStyle,
            onPressed: _stopping ? null : () => _stop(worker),
            child: Text(
              trackingState == WorkerTrackingState.pending
                  ? 'Cancel request'.tr
                  : 'Stop tracking'.tr,
            ),
          );
    return Row(
      children: [
        Expanded(child: callButton),
        const SizedBox(width: 12),
        Expanded(child: mainButton),
      ],
    );
  }
}

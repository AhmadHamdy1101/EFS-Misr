import 'package:efs_misr/core/entities/user_entity.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../data/location_source.dart';
import '../../domain/entities/tracking_worker.dart';
import '../controller/my_tracking_cubit.dart';
import '../widgets/incoming_request_card.dart';
import '../widgets/tracking_map.dart';
import '../widgets/tracking_widgets.dart';

/// Technician "My Live Location & Requests": incoming requests, sharing
/// status, and the start/stop control.
class MyLocationPage extends StatefulWidget {
  const MyLocationPage({
    super.key,
    required this.user,
    this.showBackButton = false,
  });

  final UserEntity user;

  /// True when opened as its own page (from a notification), not as a tab.
  final bool showBackButton;

  @override
  State<MyLocationPage> createState() => _MyLocationPageState();
}

class _MyLocationPageState extends State<MyLocationPage>
    with WidgetsBindingObserver {
  final _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<MyTrackingCubit>().refreshAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system settings: re-check permission and GPS.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MyTrackingCubit>().refreshAccess();
    }
  }

  Future<void> _runAction(
    Future<dynamic> Function(MyTrackingCubit cubit) action, {
    String? success,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await action(context.read<MyTrackingCubit>());
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) {
        if (success != null) showAppSnackBar(messenger, success.tr);
      },
    );
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Stop sharing'.tr),
        content: Text('Administrators will no longer see your location.'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Stop sharing'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _runAction((cubit) => cubit.stopSharing());
    }
  }

  WorkerTrackingState _chipState(MyTrackingState state) {
    if (state.pendingRequest != null) return WorkerTrackingState.pending;
    if (state.sharing) return WorkerTrackingState.live;
    if (state.isActive) return WorkerTrackingState.offline;
    return WorkerTrackingState.notSharing;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyTrackingCubit, MyTrackingState>(
      // Messages are shown app-wide by HomePage; here the map follows the fix.
      listenWhen: (previous, current) => previous.lastFix != current.lastFix,
      listener: (context, state) {
        final fix = state.lastFix;
        if (_mapReady && fix != null) {
          _mapController.move(
            LatLng(fix.latitude, fix.longitude),
            _mapController.camera.zoom < 14 ? 15 : _mapController.camera.zoom,
          );
        }
      },
      builder: (context, state) {
        final user = widget.user;
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.black87,
            automaticallyImplyLeading: widget.showBackButton,
            title: Text(
              'My Live Location & Requests'.tr,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          body: Column(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.27,
                child: _map(state),
              ),
              Expanded(
                child: state.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                        children: [
                          Row(
                            children: [
                              WorkerAvatar(user: user, radius: 38),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (user.position?.name ?? user.role).tr,
                                      style: const TextStyle(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TrackingStatusChip(
                                state: _chipState(state),
                                large: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          if (state.pendingRequest != null) ...[
                            IncomingRequestCard(request: state.pendingRequest!),
                            const SizedBox(height: 24),
                          ],
                          ..._status(state),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                  child: _mainButton(state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _map(MyTrackingState state) {
    final fix = state.lastFix;
    final branch = state.branch;
    final position = fix == null ? null : LatLng(fix.latitude, fix.longitude);
    final branchPoint = branch != null && branch.hasCoordinates
        ? LatLng(branch.latitude!, branch.longitude!)
        : null;
    return TrackingMap(
      controller: _mapController,
      initialCenter: position ?? branchPoint ?? defaultMapCenter,
      initialZoom: position != null ? 15 : 10,
      showZoomButtons: false,
      onMapReady: () => _mapReady = true,
      markers: [
        if (branchPoint != null)
          Marker(
            point: branchPoint,
            width: 44,
            height: 44,
            child: const BranchMarker(),
          ),
        Marker(
          point: position ?? defaultMapCenter,
          width: 64,
          height: 64,
          child: state.sharing
              ? const WorkerMarker(live: true)
              : const IdleMarker(),
        ),
      ],
    );
  }

  List<Widget> _status(MyTrackingState state) {
    final cubit = context.read<MyTrackingCubit>();
    final access = state.access;
    final session = state.session;
    final widgets = <Widget>[];
    void add(Widget widget) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 24));
      widgets.add(widget);
    }

    if (state.sharing) {
      add(
        TrackingInfoRow(
          icon: Icons.my_location,
          title: 'Sharing Live Location'.tr,
          subtitle:
              '${'Last sent'.tr}: ${timeAgo(state.lastPublishedAt, DateTime.now())}',
        ),
      );
      add(
        TrackingInfoRow(
          icon: Icons.visibility_outlined,
          title: 'Who can see you'.tr,
          subtitle: 'Administrators only.'.tr,
        ),
      );
    } else if (state.isPaused) {
      add(
        TrackingInfoRow(
          icon: Icons.pause_circle_outline,
          iconColor: const Color(0xffD97706),
          title: 'Sharing Paused'.tr,
          subtitle:
              session?.deviceId != null && session!.deviceId != cubit.deviceId
              ? 'Your location is being shared from another device.'.tr
              : 'Your session is open but this phone is not sending its '
                        'location. Tap resume to continue.'
                    .tr,
        ),
      );
    } else if (state.pendingRequest == null) {
      add(
        TrackingInfoRow(
          icon: Icons.track_changes,
          title: 'Location Sharing Is Off'.tr,
          subtitle: 'Start sharing whenever your team needs to see you.'.tr,
        ),
      );
    }

    if (state.connectionLost) {
      add(
        TrackingInfoRow(
          icon: Icons.wifi_off,
          iconColor: const Color(0xffD97706),
          title: 'No connection'.tr,
          subtitle:
              'Your location will be sent when the connection is back.'.tr,
        ),
      );
    }

    switch (access) {
      case LocationAccess.serviceDisabled:
        add(
          _accessProblem(
            'Location services are off'.tr,
            'Turn on GPS to share your location.'.tr,
            'Open location settings',
            cubit.openLocationSettings,
          ),
        );
      case LocationAccess.deniedForever:
        add(
          _accessProblem(
            'Location permission blocked'.tr,
            'Allow location access for EFS in the app settings.'.tr,
            'Open app settings',
            cubit.openAppSettings,
          ),
        );
      case LocationAccess.approximate:
        add(
          TrackingInfoRow(
            icon: Icons.gps_not_fixed,
            iconColor: const Color(0xffD97706),
            title: 'Approximate location only'.tr,
            subtitle: 'Turn on precise location for an accurate position.'.tr,
          ),
        );
      default:
        break;
    }

    if (state.isActive && session != null) {
      if (session.arrivedAt != null) {
        add(
          TrackingInfoRow(
            icon: Icons.flag,
            title: 'Arrived at branch'.tr,
            subtitle: DateFormat('hh:mm a').format(session.arrivedAt!),
          ),
        );
      } else if (session.ticketId != null) {
        add(
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green, width: 2),
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: state.busy
                ? null
                : () => _runAction(
                    (c) => c.markArrived(),
                    success: 'Arrival confirmed.',
                  ),
            icon: const Icon(Icons.flag_outlined),
            label: Text(
              '${'I have arrived'.tr}'
              '${state.branch == null ? '' : ' – ${state.branch!.name}'}',
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _accessProblem(
    String title,
    String subtitle,
    String action,
    Future<void> Function() onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrackingInfoRow(
          icon: Icons.location_disabled,
          iconColor: Colors.red,
          title: title,
          subtitle: subtitle,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.green),
            onPressed: onTap,
            child: Text(action.tr),
          ),
        ),
      ],
    );
  }

  Widget _mainButton(MyTrackingState state) {
    if (state.pendingRequest != null) return const SizedBox.shrink();
    if (state.sharing) {
      return TrackingPrimaryButton(
        label: 'Stop Sharing Location',
        icon: Icons.location_off,
        color: const Color(0xffC62828),
        loading: state.busy,
        onPressed: _confirmStop,
      );
    }
    return TrackingPrimaryButton(
      label: state.isPaused ? 'Resume Sharing' : 'Start Sharing Location',
      icon: Icons.location_on,
      loading: state.busy,
      onPressed: () => _runAction(
        (cubit) => cubit.startSharing(),
        success: 'You are now sharing your location.',
      ),
    );
  }
}

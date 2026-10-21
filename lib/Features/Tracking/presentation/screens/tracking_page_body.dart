import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../../../core/entities/user_entity.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../Auth/presentation/viewmodel/auth_cubit.dart';
import '../../data/models/worker_location_model.dart';
import '../controller/tracking_cubit.dart';
import '../controller/tracking_state.dart';
import '../widgets/status_badge.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/tracking_stats_row.dart';
import '../widgets/tracking_workers_sheet.dart';

class TrackingPageBody extends StatefulWidget {
  const TrackingPageBody({super.key, this.user});

  final UserEntity? user;

  @override
  State<TrackingPageBody> createState() => _TrackingPageBodyState();
}

class _TrackingPageBodyState extends State<TrackingPageBody>
    with SingleTickerProviderStateMixin {
  MapStyleType _currentMapStyle = MapStyleType.openStreetMap;
  final MapController _mapController = MapController();
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  UserEntity? get _currentUser {
    if (widget.user != null) return widget.user;
    final authState = context.read<AuthCubit>().state;
    if (authState is SessionExist) {
      return authState.user;
    }
    return null;
  }

  String get _userRole {
    final user = _currentUser;
    return user?.role ?? 'Admin';
  }

  bool get _isAdmin => _userRole == 'Admin';
  bool get _isUser => _userRole == 'User';
  bool get _isWorker =>
      _userRole == 'Worker' || _userRole == 'Technician' || (!_isAdmin && !_isUser);

  String _getTileUrlTemplate() {
    switch (_currentMapStyle) {
      case MapStyleType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyleType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyleType.cartoDark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapStyleType.cartoLight:
        return 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingCubit, TrackingState>(
      listener: (context, state) {
        if (state.toastMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.toastMessage!)),
                ],
              ),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<TrackingCubit>().clearToast();
        }
      },
      builder: (context, state) {
        // 1. Worker / Technician View (Make live location & view requests on map)
        if (_isWorker) {
          return _buildWorkerPersonalPortal(context, state);
        }

        // 2. User View (See map and track all workers without request)
        if (_isUser) {
          return _buildUserTrackingView(context, state);
        }

        // 3. Admin View (Full control: map, send request, see all workers)
        switch (state.currentView) {
          case TrackingViewType.dashboard:
            return _buildDashboardView(context, state);
          case TrackingViewType.requestConfirmation:
            return Stack(
              children: [
                _buildDashboardView(context, state),
                _buildRequestModal(context, state),
              ],
            );
          case TrackingViewType.pendingApproval:
            return _buildPendingScreen(context, state);
          case TrackingViewType.workerDetail:
            return _buildWorkerDetailView(context, state);
          case TrackingViewType.incomingRequest:
            return _buildIncomingRequestView(context, state);
          case TrackingViewType.sharingOff:
            return _buildSharingOffView(context, state);
          case TrackingViewType.sharingActive:
            return _buildSharingActiveView(context, state);
          case TrackingViewType.stopConfirmation:
            return Stack(
              children: [
                _buildSharingActiveView(context, state),
                _buildStopConfirmationModal(context, state),
              ],
            );
        }
      },
    );
  }

  // ===========================================================================
  // USER TRACKING VIEW (See map & track all workers without request)
  // ===========================================================================
  Widget _buildUserTrackingView(BuildContext context, TrackingState state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final liveCount = state.workers
        .where((WorkerLocationModel w) => w.status == WorkerStatus.live)
        .length;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.scafolddark : AppColors.appBackground,
      appBar: AppBar(
        title: Text('Live Workers Map'.tr),
        backgroundColor: AppColors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: isDarkMode ? AppColors.buttondark : AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed,
                              color: AppColors.successGreen),
                          const SizedBox(width: 10),
                          Text(
                            '$liveCount Workers Active on Map'.tr,
                            style: AppTextStyle.latoBold16(context).copyWith(
                              color:
                                  isDarkMode ? AppColors.white : AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TrackingMapWidget(
                    state: state,
                    mapController: _mapController,
                    currentMapStyle: _currentMapStyle,
                    onMarkerTap: (worker) {
                      context.read<TrackingCubit>().selectWorker(worker);
                      _mapController.move(worker.location, 15.0);
                    },
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'userMapZoomIn',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    onPressed: () {
                      final zoom = _mapController.camera.zoom + 1;
                      _mapController.move(_mapController.camera.center, zoom);
                    },
                    child: const Icon(Icons.add, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WORKER PERSONAL PORTAL (For Non-Admin Workers / Technicians)
  // ===========================================================================
  Widget _buildWorkerPersonalPortal(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final workerName = _currentUser?.name ?? 'Ahmed Hassan';
    final worker = state.workers.firstWhere(
      (w) => w.name.toLowerCase() == workerName.toLowerCase(),
      orElse: () => state.workers[1],
    );

    final isLive = worker.status == WorkerStatus.live;
    final isPending =
        worker.status == WorkerStatus.pending || worker.isLocationRequested;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Live Location & Requests'.tr),
        backgroundColor: AppColors.green,
      ),
      body: Column(
        children: [
          // Map showing worker's own location
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: worker.location,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _getTileUrlTemplate(),
                  userAgentPackageName: 'com.efsmisr.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: worker.location,
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLive ? AppColors.successGreen : AppColors.gray,
                              boxShadow: [
                                BoxShadow(
                                  color: (isLive ? AppColors.successGreen : AppColors.gray)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(color: AppColors.white, width: 3),
                            ),
                            child: const Icon(Icons.person, color: AppColors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(worker.avatarUrl),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.name,
                              style: AppTextStyle.latoBold16(context),
                            ),
                            Text(
                              worker.position,
                              style: AppTextStyle.latoRegular12(context)
                                  .copyWith(color: AppColors.gray),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: worker.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.appBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radar, color: AppColors.green, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPending
                                    ? 'Location Request from Operations'.tr
                                    : isLive
                                        ? 'Sharing Active (You are visible)'.tr
                                        : 'Location Sharing Is Off'.tr,
                                style: AppTextStyle.latoBold16(context),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPending
                                    ? 'Operations has requested access to your live location.'
                                    : isLive
                                        ? 'Your team can see your live marker on the map.'
                                        : 'Start sharing whenever your team needs to see you.',
                                style: AppTextStyle.latoRegular12(context)
                                    .copyWith(color: AppColors.gray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isPending) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => cubit.simulateApproval(worker),
                        icon: const Icon(Icons.check, color: AppColors.white),
                        label: Text('Accept & Start Sharing'.tr,
                            style: const TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => cubit.cancelRequest(worker),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Decline Request'.tr),
                      ),
                    ),
                  ] else if (isLive) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => cubit.stopSharing(worker),
                        icon: const Icon(Icons.stop, color: AppColors.white),
                        label: Text('Stop Sharing Location'.tr,
                            style: const TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => cubit.startSharing(),
                        icon: const Icon(Icons.location_on, color: AppColors.white),
                        label: Text('Start Sharing Location'.tr,
                            style: const TextStyle(color: AppColors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. ADMIN DASHBOARD VIEW (Map behind, Draggable Sheet above)
  // ===========================================================================
  Widget _buildDashboardView(BuildContext context, TrackingState state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<TrackingCubit>();

    final liveCount = state.workers
        .where((WorkerLocationModel w) => w.status == WorkerStatus.live)
        .length;
    final offlineCount = state.workers
        .where((WorkerLocationModel w) => w.status == WorkerStatus.offline)
        .length;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.scafolddark : AppColors.appBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPERATIONS (ADMIN)'.tr,
              style: AppTextStyle.latoBold10(context).copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Live Tracking Control'.tr,
              style: AppTextStyle.latoBold20(context).copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.green, AppColors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.white),
            onPressed: () {
              cubit.navigateTo(TrackingViewType.incomingRequest,
                  targetWorker: state.workers[1]);
            },
            tooltip: 'Worker View Demo'.tr,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Stats Card Row
          TrackingStatsRow(
            totalWorkers: state.workers.length,
            liveCount: liveCount,
            offlineCount: offlineCount,
            isDarkMode: isDarkMode,
          ),

          // Map & Draggable Sheet Above It
          Expanded(
            child: Stack(
              children: [
                // 1. Map filling the background
                Positioned.fill(
                  child: TrackingMapWidget(
                    state: state,
                    mapController: _mapController,
                    currentMapStyle: _currentMapStyle,
                    onMarkerTap: (worker) {
                      cubit.selectWorker(worker);
                      _mapController.move(worker.location, 15.0);
                    },
                  ),
                ),

                // 2. Map Floating Zoom Controls
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'mapZoomIn',
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                        onPressed: () {
                          final zoom = _mapController.camera.zoom + 1;
                          _mapController.move(_mapController.camera.center, zoom);
                        },
                        child: const Icon(Icons.add, size: 18),
                      ),
                      const SizedBox(height: 4),
                      FloatingActionButton.small(
                        heroTag: 'mapZoomOut',
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                        onPressed: () {
                          final zoom = _mapController.camera.zoom - 1;
                          _mapController.move(_mapController.camera.center, zoom);
                        },
                        child: const Icon(Icons.remove, size: 18),
                      ),
                    ],
                  ),
                ),

                // 3. Draggable / Sliding Workers Sheet that goes up and down above the map
                DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.22,
                  maxChildSize: 0.88,
                  builder: (context, scrollController) {
                    return TrackingWorkersSheet(
                      state: state,
                      scrollController: scrollController,
                      isDarkMode: isDarkMode,
                      onStyleSelected: (style) =>
                          setState(() => _currentMapStyle = style),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. REQUEST CONFIRMATION MODAL
  // ===========================================================================
  Widget _buildRequestModal(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final worker = state.targetWorker ?? state.workers[1];

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_pin, color: AppColors.green, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Request live location'.tr,
                style: AppTextStyle.latoBold20(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Send a location sharing request to ${worker.name}?',
                textAlign: TextAlign.center,
                style: AppTextStyle.latoRegular16(context).copyWith(
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.appBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(worker.avatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker.name,
                              style: AppTextStyle.latoBold13(context)),
                          Text(worker.position,
                              style: AppTextStyle.latoRegular12(context)),
                        ],
                      ),
                    ),
                    const StatusBadge(status: WorkerStatus.offline),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sharing starts only after ${worker.name} approves your request.',
                      style: AppTextStyle.latoRegular12(context).copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => cubit.sendRequest(worker),
                  icon: const Icon(Icons.location_pin, color: AppColors.white),
                  label: Text('Send request'.tr,
                      style: const TextStyle(color: AppColors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    cubit.navigateTo(TrackingViewType.dashboard),
                child: Text('Cancel'.tr,
                    style: const TextStyle(color: AppColors.gray)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. PENDING APPROVAL SCREEN
  // ===========================================================================
  Widget _buildPendingScreen(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final worker = state.targetWorker ?? state.workers[1];

    return Scaffold(
      appBar: AppBar(
        title: Text('Request pending'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => cubit.navigateTo(TrackingViewType.dashboard),
        ),
        backgroundColor: AppColors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withValues(alpha: 0.15),
                  ),
                ),
                CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(worker.avatarUrl),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Request sent to ${worker.name}',
              style: AppTextStyle.latoBold20(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll notify you as soon as ${worker.name} responds. His location remains private until he accepts.',
              style: AppTextStyle.latoRegular16(context).copyWith(
                color: AppColors.gray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status'),
                      StatusBadge(status: WorkerStatus.pending),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requested'),
                      Text('Just now',
                          style: AppTextStyle.latoBold12(context)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requested by'),
                      Text('Operations',
                          style: AppTextStyle.latoBold12(context)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => cubit.simulateApproval(worker),
                icon: const Icon(Icons.check, color: AppColors.white),
                label: Text('Simulate worker approval'.tr,
                    style: const TextStyle(color: AppColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => cubit.cancelRequest(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Cancel request'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. WORKER DETAIL VIEW
  // ===========================================================================
  Widget _buildWorkerDetailView(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final worker =
        state.targetWorker ?? state.selectedWorker ?? state.workers[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(worker.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => cubit.navigateTo(TrackingViewType.dashboard),
        ),
        backgroundColor: AppColors.green,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: worker.location,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _getTileUrlTemplate(),
                  userAgentPackageName: 'com.efsmisr.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: worker.location,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.successGreen,
                        ),
                        child: const Icon(Icons.engineering,
                            color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(worker.avatarUrl),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name,
                                style: AppTextStyle.latoBold20(context)),
                            Text(worker.position,
                                style: AppTextStyle.latoRegular16(context)
                                    .copyWith(color: AppColors.gray)),
                            const StatusBadge(status: WorkerStatus.live),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow('Current address', 'Al Noor Street, Central District'),
                  _detailRow('GPS coordinates', '25.2048° N, 55.2708° E'),
                  _detailRow('Last successful update', worker.lastUpdated),
                  _detailRow('Location accuracy', '± 8 meters'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone, color: AppColors.green),
                          label: Text('Call worker'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => cubit.navigateTo(
                              TrackingViewType.dashboard),
                          label: Text('Back to workers'.tr,
                              style: const TextStyle(color: AppColors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.gray)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. WORKER PERSPECTIVE: INCOMING REQUEST
  // ===========================================================================
  Widget _buildIncomingRequestView(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live location request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => cubit.navigateTo(TrackingViewType.dashboard),
        ),
        backgroundColor: AppColors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radar, size: 64, color: AppColors.green),
            const SizedBox(height: 20),
            Text(
              'Share your live location?',
              style: AppTextStyle.latoBold20(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Operations has requested access to your live location. Would you like to start sharing?',
              style: AppTextStyle.latoRegular16(context)
                  .copyWith(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only authorized Operations administrators can view your live location. You can stop sharing at any time.',
                      style: AppTextStyle.latoRegular12(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => cubit.startSharing(),
                icon: const Icon(Icons.check, color: AppColors.white),
                label: const Text('Accept & share',
                    style: TextStyle(color: AppColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    cubit.navigateTo(TrackingViewType.sharingOff),
                child: const Text('Decline'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. WORKER PERSPECTIVE: SHARING OFF
  // ===========================================================================
  Widget _buildSharingOffView(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
        backgroundColor: AppColors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StatusBadge(status: WorkerStatus.offline),
            const SizedBox(height: 16),
            Text(
              'Location sharing is off',
              style: AppTextStyle.latoBold20(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Your location is not currently being shared. Start sharing whenever your team needs to see you.',
              textAlign: TextAlign.center,
              style: AppTextStyle.latoRegular16(context)
                  .copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => cubit.startSharing(),
                icon: const Icon(Icons.location_on, color: AppColors.white),
                label: const Text('Start sharing location',
                    style: TextStyle(color: AppColors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => cubit.navigateTo(TrackingViewType.dashboard),
              child: const Text('Back to Admin Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. WORKER PERSPECTIVE: SHARING ACTIVE
  // ===========================================================================
  Widget _buildSharingActiveView(BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final worker = state.targetWorker ?? state.workers[1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
        backgroundColor: AppColors.green,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.green.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Live location active',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const StatusBadge(status: WorkerStatus.live),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: worker.location,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _getTileUrlTemplate(),
                  userAgentPackageName: 'com.efsmisr.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: worker.location,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.engineering,
                          color: AppColors.successGreen, size: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => cubit.navigateTo(
                        TrackingViewType.stopConfirmation,
                        targetWorker: worker),
                    icon: const Icon(Icons.stop, color: AppColors.white),
                    label: const Text('Stop sharing',
                        style: TextStyle(color: AppColors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. STOP CONFIRMATION MODAL
  // ===========================================================================
  Widget _buildStopConfirmationModal(
      BuildContext context, TrackingState state) {
    final cubit = context.read<TrackingCubit>();
    final worker = state.targetWorker ?? state.workers[1];

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop_circle, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Stop sharing location?'.tr,
                style: AppTextStyle.latoBold20(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Your live location will no longer be visible to the Operations team.',
                textAlign: TextAlign.center,
                style: AppTextStyle.latoRegular16(context).copyWith(
                  color: AppColors.gray,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => cubit.stopSharing(worker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Stop sharing'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    cubit.navigateTo(TrackingViewType.sharingActive),
                child: const Text('Keep sharing',
                    style: TextStyle(color: AppColors.gray)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

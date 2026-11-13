import 'package:efs_misr/core/auth/permissions_context.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../Notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/tracking_worker.dart';
import '../controller/tracking_control_cubit.dart';
import '../widgets/request_location_dialog.dart';
import '../widgets/tracking_map.dart';
import '../widgets/tracking_widgets.dart';
import '../widgets/worker_tile.dart';
import 'worker_tracking_page.dart';

/// "Live Tracking Control": counts, a map of live workers, and the worker
/// list. Admins can request/cancel; with [readOnly] (role User) the screen
/// only shows workers and their live locations.
class TrackingControlPage extends StatefulWidget {
  const TrackingControlPage({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  State<TrackingControlPage> createState() => _TrackingControlPageState();
}

class _TrackingControlPageState extends State<TrackingControlPage>
    with WidgetsBindingObserver {
  final _mapController = MapController();
  final _search = TextEditingController();
  TrackingMapStyle _style = TrackingMapStyle.standard;
  bool _mapReady = false;
  bool _fittedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  /// Realtime can drop silently while the app is in the background; re-read
  /// the current state when the user comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TrackingControlCubit>().refresh();
    }
  }

  void _openWorker(TrackingWorker worker) {
    Get.to(
      () => WorkerTrackingPage(
        technicianId: worker.user.id,
        readOnly: widget.readOnly,
      ),
    );
  }

  /// Shows every mapped worker once the first positions arrive, then leaves
  /// the camera to the user (updates don't move it).
  void _fitToWorkers(List<TrackingWorker> workers, {bool force = false}) {
    if (!_mapReady || (_fittedOnce && !force)) return;
    final points = [
      for (final worker in workers)
        LatLng(worker.session!.latitude!, worker.session!.longitude!),
    ];
    if (points.isEmpty) return;
    _fittedOnce = true;
    if (points.length == 1) {
      _mapController.move(points.first, 15);
    } else {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(60),
          maxZoom: 16,
        ),
      );
    }
  }

  Future<void> _cancelPending(TrackingWorker worker) async {
    final session = worker.session;
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel request'.tr),
        content: Text(
          '${'Cancel the location request to'.tr} ${worker.user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Keep'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Cancel request'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<TrackingControlCubit>().cancel(session);
    result.fold(
      (failure) => showAppSnackBar(messenger, failure.message, isError: true),
      (_) => showAppSnackBar(messenger, 'Request cancelled.'.tr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingControlCubit, TrackingControlState>(
      listenWhen: (previous, current) =>
          previous.noticeId != current.noticeId ||
          previous.mappedWorkers.length != current.mappedWorkers.length,
      listener: (context, state) {
        if (state.notice != null && !widget.readOnly) {
          showAppSnackBar(ScaffoldMessenger.of(context), state.notice!);
        }
        _fitToWorkers(state.mappedWorkers);
      },
      builder: (context, state) {
        final sizes = TrackingSizes.of(context);
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final map = _map(state, sizes);
        final list = _WorkersList(
          state: state,
          search: _search,
          readOnly: widget.readOnly,
          onToggleStyle: () => setState(() => _style = _style.next),
          onView: _openWorker,
          onRequest: (worker) =>
              RequestLocationDialog.show(context, worker: worker),
          onCancelPending: _cancelPending,
        );

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          body: Column(
            children: [
              _Header(
                readOnly: widget.readOnly,
                onRefresh: context.read<TrackingControlCubit>().refresh,
              ),
              if (!landscape) _Stats(state: state, sizes: sizes),
              Expanded(
                child: landscape
                    // Side by side: the list never covers the map.
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: map),
                          SizedBox(
                            width: 360,
                            child: ColoredBox(
                              color: Colors.white,
                              child: list.scrollable(null),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned.fill(child: map),
                          DraggableScrollableSheet(
                            initialChildSize: 0.45,
                            minChildSize: 0.2,
                            maxChildSize: 0.92,
                            builder: (context, controller) => DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: list.scrollable(controller),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _map(TrackingControlState state, TrackingSizes sizes) {
    return Stack(
      children: [
        Positioned.fill(
          child: TrackingMap(
            controller: _mapController,
            style: _style,
            onMapReady: () {
              _mapReady = true;
              _fitToWorkers(state.mappedWorkers);
            },
            onRecenter: state.mappedWorkers.isEmpty
                ? null
                : () => _fitToWorkers(state.mappedWorkers, force: true),
            markers: [
              for (final worker in state.mappedWorkers)
                Marker(
                  key: ValueKey(worker.user.id),
                  point: LatLng(
                    worker.session!.latitude!,
                    worker.session!.longitude!,
                  ),
                  width: sizes.marker,
                  height: sizes.marker,
                  child: GestureDetector(
                    onTap: () => _openWorker(worker),
                    child: Tooltip(
                      message: worker.user.name,
                      child: WorkerMarker(
                        size: sizes.marker,
                        live:
                            worker.stateAt(state.now) ==
                            WorkerTrackingState.live,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (state.realtimeLost)
          PositionedDirectional(
            start: 12,
            top: 12,
            child: _Banner(text: 'Reconnecting…'.tr),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.readOnly, required this.onRefresh});

  final bool readOnly;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final sizes = TrackingSizes.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff00A651), Color(0xff00C95F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            sizes.gutter + 4,
            sizes.compact ? 10 : 14,
            4,
            sizes.compact ? 10 : 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (readOnly ? 'OPERATIONS' : 'OPERATIONS (ADMIN)').tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live Tracking Control'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sizes.compact ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh'.tr,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
              const NotificationBell(
                icon: Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.state, required this.sizes});

  final TrackingControlState state;
  final TrackingSizes sizes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(sizes.gutter),
      child: Row(
        children: [
          Expanded(
            child: TrackingStatCard(
              icon: Icons.groups_outlined,
              value: state.workers.length,
              label: 'Total workers',
            ),
          ),
          SizedBox(width: sizes.compact ? 8 : 12),
          Expanded(
            child: TrackingStatCard(
              icon: Icons.my_location,
              value: state.countOf(WorkerTrackingState.live),
              label: 'Live now',
            ),
          ),
          SizedBox(width: sizes.compact ? 8 : 12),
          Expanded(
            child: TrackingStatCard(
              icon: Icons.location_off_outlined,
              iconColor: AppColors.gray,
              iconBackground: const Color(0xffE6E6E6),
              value: state.countOf(WorkerTrackingState.notSharing),
              label: 'Not sharing',
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFFF1DC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xffB45309)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xffB45309))),
        ],
      ),
    );
  }
}

/// Search, filter chips and the worker rows; used in the bottom sheet
/// (portrait) and the side panel (landscape).
class _WorkersList {
  const _WorkersList({
    required this.state,
    required this.search,
    required this.readOnly,
    required this.onToggleStyle,
    required this.onView,
    required this.onRequest,
    required this.onCancelPending,
  });

  final TrackingControlState state;
  final TextEditingController search;
  final bool readOnly;
  final VoidCallback onToggleStyle;
  final ValueChanged<TrackingWorker> onView;
  final ValueChanged<TrackingWorker> onRequest;
  final ValueChanged<TrackingWorker> onCancelPending;

  Widget scrollable(ScrollController? controller) => Builder(
    builder: (context) {
      final sizes = TrackingSizes.of(context);
      final cubit = context.read<TrackingControlCubit>();
      final workers = state.visibleWorkers;
      // Workers, with an engineer header (String?, null = none) before each
      // group when technicians are assigned to engineers.
      final groups = state.visibleGroups(
        viewerId: context.readPermissions.user?.id,
      );
      final List<Object?> entries = groups == null
          ? workers
          : [
              for (final group in groups) ...[
                group.engineerName,
                ...group.members,
              ],
            ];
      return CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                sizes.gutter,
                controller == null ? sizes.gutter : 10,
                sizes.gutter,
                0,
              ),
              child: Column(
                children: [
                  if (controller != null) ...[
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xffC8C8C8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Text(
                        'Workers'.tr,
                        style: TextStyle(
                          fontSize: sizes.title + 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: trackingTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.workers.length}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Map style'.tr,
                        onPressed: onToggleStyle,
                        icon: const Icon(
                          Icons.layers_outlined,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: search,
                    onChanged: cubit.search,
                    style: TextStyle(fontSize: sizes.body + 1),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search workers...'.tr,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: trackingCardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final (index, filter) in WorkerFilter.values.indexed)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: index == 0 ? 0 : 6,
                            ),
                            child: _FilterChip(
                              label: switch (filter) {
                                WorkerFilter.all => 'All',
                                WorkerFilter.live => 'Live',
                                WorkerFilter.offline => 'Offline',
                                WorkerFilter.pending => 'Pending',
                              },
                              height: sizes.chipHeight,
                              selected: state.filter == filter,
                              onTap: () => cubit.setFilter(filter),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (state.loading && state.workers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
              ),
            )
          else if (state.error != null && state.workers.isEmpty)
            SliverToBoxAdapter(
              child: TrackingMessage(
                icon: Icons.cloud_off,
                text: state.error!,
                onRetry: cubit.refresh,
              ),
            )
          else if (workers.isEmpty)
            SliverToBoxAdapter(
              child: TrackingMessage(
                icon: Icons.person_search,
                text: 'No workers found'.tr,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sizes.gutter, 0, sizes.gutter, 96),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  if (entry is! TrackingWorker) {
                    return _EngineerHeader(
                      name: entry as String?,
                      fontSize: sizes.body + 1,
                    );
                  }
                  final worker = entry;
                  return WorkerTile(
                    key: ValueKey(worker.user.id),
                    worker: worker,
                    now: state.now,
                    readOnly: readOnly,
                    onView: () => onView(worker),
                    onRequest: () => onRequest(worker),
                    onCancelPending: () => onCancelPending(worker),
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}

class _EngineerHeader extends StatelessWidget {
  const _EngineerHeader({required this.name, required this.fontSize});

  final String? name;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
      child: Row(
        children: [
          Icon(
            name == null ? Icons.person_off_outlined : Icons.engineering,
            size: fontSize + 4,
            color: AppColors.green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name ?? 'No engineer assigned'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : trackingCardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.tr,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

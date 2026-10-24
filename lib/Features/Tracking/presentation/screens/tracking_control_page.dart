import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:efs_misr/core/utils/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/tracking_worker.dart';
import '../../../Notifications/presentation/widgets/notification_bell.dart';
import '../controller/tracking_control_cubit.dart';
import '../widgets/request_location_dialog.dart';
import '../widgets/tracking_map.dart';
import '../widgets/tracking_widgets.dart';
import '../widgets/worker_tile.dart';
import 'worker_tracking_page.dart';

/// Admin "Live Tracking Control": counts, a map of live workers, and a
/// draggable sheet listing every worker with their sharing state.
class TrackingControlPage extends StatefulWidget {
  const TrackingControlPage({super.key});

  @override
  State<TrackingControlPage> createState() => _TrackingControlPageState();
}

class _TrackingControlPageState extends State<TrackingControlPage> {
  final _mapController = MapController();
  final _search = TextEditingController();
  TrackingMapStyle _style = TrackingMapStyle.standard;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openWorker(TrackingWorker worker) {
    Get.to(() => WorkerTrackingPage(technicianId: worker.user.id));
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
      listenWhen: (previous, current) => previous.noticeId != current.noticeId,
      listener: (context, state) {
        if (state.notice != null) {
          showAppSnackBar(ScaffoldMessenger.of(context), state.notice!);
        }
      },
      builder: (context, state) {
        final cubit = context.read<TrackingControlCubit>();
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          body: Column(
            children: [
              _Header(onRefresh: cubit.refresh),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TrackingStatCard(
                        icon: Icons.groups_outlined,
                        value: state.workers.length,
                        label: 'Total workers',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TrackingStatCard(
                        icon: Icons.my_location,
                        value: state.countOf(WorkerTrackingState.live),
                        label: 'Live now',
                      ),
                    ),
                    const SizedBox(width: 14),
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
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TrackingMap(
                        controller: _mapController,
                        style: _style,
                        markers: [
                          for (final worker in state.mappedWorkers)
                            Marker(
                              point: LatLng(
                                worker.session!.latitude!,
                                worker.session!.longitude!,
                              ),
                              width: 64,
                              height: 64,
                              child: GestureDetector(
                                onTap: () => _openWorker(worker),
                                child: WorkerMarker(
                                  live:
                                      worker.stateAt(state.now) ==
                                      WorkerTrackingState.live,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state.realtimeLost)
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _Banner(text: 'Reconnecting…'.tr),
                      ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.5,
                      minChildSize: 0.18,
                      maxChildSize: 0.95,
                      builder: (context, scrollController) => _WorkersSheet(
                        state: state,
                        scrollController: scrollController,
                        search: _search,
                        onToggleStyle: () =>
                            setState(() => _style = _style.next),
                        onView: _openWorker,
                        onRequest: (worker) =>
                            RequestLocationDialog.show(context, worker: worker),
                        onCancelPending: _cancelPending,
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff00A651), Color(0xff00C95F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 12, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATIONS (ADMIN)'.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live Tracking Control'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh'.tr,
                onPressed: onRefresh,
                icon: const Icon(Icons.menu, color: Colors.white, size: 32),
              ),
              // Persistent notifications (tracking events included).
              const NotificationBell(
                icon: Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
        ),
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
          const Icon(Icons.wifi_off, size: 16, color: Color(0xffD97706)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xffD97706))),
        ],
      ),
    );
  }
}

class _WorkersSheet extends StatelessWidget {
  const _WorkersSheet({
    required this.state,
    required this.scrollController,
    required this.search,
    required this.onToggleStyle,
    required this.onView,
    required this.onRequest,
    required this.onCancelPending,
  });

  final TrackingControlState state;
  final ScrollController scrollController;
  final TextEditingController search;
  final VoidCallback onToggleStyle;
  final ValueChanged<TrackingWorker> onView;
  final ValueChanged<TrackingWorker> onRequest;
  final ValueChanged<TrackingWorker> onCancelPending;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrackingControlCubit>();
    final workers = state.visibleWorkers;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffC8C8C8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Workers'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
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
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: search,
                    onChanged: cubit.search,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Search workers...'.tr,
                      hintStyle: const TextStyle(fontSize: 20),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.search, size: 30),
                      ),
                      filled: true,
                      fillColor: trackingCardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (final (index, filter) in WorkerFilter.values.indexed)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                            child: _FilterChip(
                              label: switch (filter) {
                                WorkerFilter.all => 'All',
                                WorkerFilter.live => 'Live',
                                WorkerFilter.offline => 'Offline',
                                WorkerFilter.pending => 'Pending',
                              },
                              selected: state.filter == filter,
                              onTap: () => cubit.setFilter(filter),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(state.error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: cubit.refresh,
                      child: Text('Retry'.tr),
                    ),
                  ],
                ),
              ),
            )
          else if (workers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text('No workers found'.tr)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.separated(
                itemCount: workers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return WorkerTile(
                    worker: worker,
                    now: state.now,
                    onView: () => onView(worker),
                    onRequest: () => onRequest(worker),
                    onCancelPending: () => onCancelPending(worker),
                  );
                },
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : trackingCardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            label.tr,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

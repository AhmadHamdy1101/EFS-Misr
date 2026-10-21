import '../../data/models/worker_location_model.dart';

enum TrackingViewType {
  dashboard,
  requestConfirmation,
  pendingApproval,
  workerDetail,
  incomingRequest,
  sharingOff,
  sharingActive,
  stopConfirmation,
}

class TrackingState {
  final List<WorkerLocationModel> workers;
  final WorkerLocationModel? selectedWorker;
  final WorkerLocationModel? targetWorker;
  final String filterTab; // "All", "Live", "Offline", "Pending"
  final String searchQuery;
  final TrackingViewType currentView;
  final String? toastMessage;

  const TrackingState({
    required this.workers,
    this.selectedWorker,
    this.targetWorker,
    this.filterTab = 'All',
    this.searchQuery = '',
    this.currentView = TrackingViewType.dashboard,
    this.toastMessage,
  });

  TrackingState copyWith({
    List<WorkerLocationModel>? workers,
    WorkerLocationModel? selectedWorker,
    WorkerLocationModel? targetWorker,
    String? filterTab,
    String? searchQuery,
    TrackingViewType? currentView,
    String? toastMessage,
  }) {
    return TrackingState(
      workers: workers ?? this.workers,
      selectedWorker: selectedWorker ?? this.selectedWorker,
      targetWorker: targetWorker ?? this.targetWorker,
      filterTab: filterTab ?? this.filterTab,
      searchQuery: searchQuery ?? this.searchQuery,
      currentView: currentView ?? this.currentView,
      toastMessage: toastMessage,
    );
  }
}

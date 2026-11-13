import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/worker_location_model.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit()
      : super(TrackingState(
          workers: WorkerLocationModel.getInitialWorkers(),
          selectedWorker: WorkerLocationModel.getInitialWorkers().first,
        ));

  void setFilterTab(String tab) {
    emit(state.copyWith(filterTab: tab));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void selectWorker(WorkerLocationModel? worker) {
    emit(state.copyWith(selectedWorker: worker));
  }

  void navigateTo(TrackingViewType view, {WorkerLocationModel? targetWorker}) {
    emit(state.copyWith(
      currentView: view,
      targetWorker: targetWorker ?? state.targetWorker,
    ));
  }

  void sendRequest(WorkerLocationModel worker) {
    final updatedWorkers = state.workers.map((w) {
      if (w.id == worker.id) {
        return w.copyWith(
          status: WorkerStatus.pending,
          lastUpdated: "Sent just now",
          isLocationRequested: true,
          requestedAt: DateTime.now(),
        );
      }
      return w;
    }).toList();

    emit(state.copyWith(
      workers: updatedWorkers,
      currentView: TrackingViewType.dashboard,
      toastMessage: "Location request sent to ${worker.name}",
    ));
  }

  void simulateApproval(WorkerLocationModel worker) {
    final updatedWorkers = state.workers.map((w) {
      if (w.id == worker.id) {
        return w.copyWith(
          status: WorkerStatus.live,
          lastUpdated: "Just now",
        );
      }
      return w;
    }).toList();

    emit(state.copyWith(
      workers: updatedWorkers,
      currentView: TrackingViewType.dashboard,
      toastMessage: "${worker.name} accepted and is now live",
    ));
  }

  void cancelRequest(WorkerLocationModel worker) {
    final updatedWorkers = state.workers.map((w) {
      if (w.id == worker.id) {
        return w.copyWith(
          status: WorkerStatus.offline,
          lastUpdated: "Not sharing",
          isLocationRequested: false,
        );
      }
      return w;
    }).toList();

    emit(state.copyWith(
      workers: updatedWorkers,
      currentView: TrackingViewType.dashboard,
      toastMessage: "Location request cancelled",
    ));
  }

  void startSharing() {
    final target = state.targetWorker ?? state.workers[1];
    final updatedWorkers = state.workers.map((w) {
      if (w.id == target.id) {
        return w.copyWith(
          status: WorkerStatus.live,
          lastUpdated: "Just now",
        );
      }
      return w;
    }).toList();

    emit(state.copyWith(
      workers: updatedWorkers,
      currentView: TrackingViewType.sharingActive,
      targetWorker: target,
      toastMessage: "Location permission granted. You’re live.",
    ));
  }

  void stopSharing(WorkerLocationModel worker) {
    final updatedWorkers = state.workers.map((w) {
      if (w.id == worker.id) {
        return w.copyWith(
          status: WorkerStatus.offline,
          lastUpdated: "Not sharing",
          isLocationRequested: false,
        );
      }
      return w;
    }).toList();

    emit(state.copyWith(
      workers: updatedWorkers,
      currentView: TrackingViewType.sharingOff,
      targetWorker: worker,
      toastMessage: "Location sharing stopped",
    ));
  }

  void clearToast() {
    emit(state.copyWith(toastMessage: null));
  }
}

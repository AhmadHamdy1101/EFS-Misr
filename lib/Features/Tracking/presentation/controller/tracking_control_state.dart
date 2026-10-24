part of 'tracking_control_cubit.dart';

enum WorkerFilter { all, live, offline, pending }

class TrackingNotice {
  const TrackingNotice(this.message, this.at);

  final String message;
  final DateTime at;
}

class TrackingControlState {
  const TrackingControlState({
    required this.now,
    this.loading = false,
    this.error,
    this.workers = const [],
    this.sessions = const {},
    this.query = '',
    this.filter = WorkerFilter.all,
    this.realtimeLost = false,
    this.notice,
    this.noticeId = 0,
    this.notices = const [],
  });

  /// Reference time for freshness, refreshed by the cubit's tick.
  final DateTime now;
  final bool loading;
  final String? error;
  final List<UserEntity> workers;

  /// Open session per technician id.
  final Map<BigInt, TrackingSession> sessions;
  final String query;
  final WorkerFilter filter;
  final bool realtimeLost;

  /// Latest event for a snackbar; [noticeId] changes with each one.
  final String? notice;
  final int noticeId;
  final List<TrackingNotice> notices;

  List<TrackingWorker> get allWorkers => [
    for (final worker in workers)
      TrackingWorker(user: worker, session: sessions[worker.id]),
  ];

  /// Workers matching the search and the selected chip, live ones first.
  List<TrackingWorker> get visibleWorkers {
    final result = allWorkers.where((worker) {
      final user = worker.user;
      if (query.isNotEmpty &&
          !user.name.toLowerCase().contains(query) &&
          !(user.position?.name?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      final trackingState = worker.stateAt(now);
      return switch (filter) {
        WorkerFilter.all => true,
        WorkerFilter.live => trackingState == WorkerTrackingState.live,
        WorkerFilter.offline => trackingState == WorkerTrackingState.offline,
        WorkerFilter.pending => trackingState == WorkerTrackingState.pending,
      };
    }).toList();
    result.sort((a, b) => a.stateAt(now).index.compareTo(b.stateAt(now).index));
    return result;
  }

  /// Workers with a position to draw on the map.
  List<TrackingWorker> get mappedWorkers => [
    for (final worker in allWorkers)
      if (worker.session?.status == TrackingStatus.active &&
          (worker.session?.hasLocation ?? false))
        worker,
  ];

  int countOf(WorkerTrackingState trackingState) =>
      allWorkers.where((w) => w.stateAt(now) == trackingState).length;

  TrackingWorker? workerById(BigInt id) {
    for (final worker in workers) {
      if (worker.id == id) {
        return TrackingWorker(user: worker, session: sessions[id]);
      }
    }
    return null;
  }

  TrackingControlState copyWith({
    DateTime? now,
    bool? loading,
    String? error,
    bool clearError = false,
    List<UserEntity>? workers,
    Map<BigInt, TrackingSession>? sessions,
    String? query,
    WorkerFilter? filter,
    bool? realtimeLost,
    String? notice,
    int? noticeId,
    List<TrackingNotice>? notices,
  }) {
    return TrackingControlState(
      now: now ?? this.now,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      workers: workers ?? this.workers,
      sessions: sessions ?? this.sessions,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      realtimeLost: realtimeLost ?? this.realtimeLost,
      notice: notice ?? this.notice,
      noticeId: noticeId ?? this.noticeId,
      notices: notices ?? this.notices,
    );
  }
}

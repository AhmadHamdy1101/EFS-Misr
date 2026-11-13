part of 'my_tracking_cubit.dart';

class MyTrackingState {
  const MyTrackingState({
    this.loading = false,
    this.busy = false,
    this.session,
    this.branch,
    this.access,
    this.sharing = false,
    this.connectionLost = false,
    this.lastFix,
    this.lastPublishedAt,
    this.message,
    this.messageId = 0,
  });

  final bool loading;

  /// An accept/decline/start/stop call is in flight.
  final bool busy;

  /// The open (pending or active) session, if any.
  final TrackingSession? session;
  final BranchLocation? branch;
  final LocationAccess? access;

  /// This device is collecting and publishing positions.
  final bool sharing;

  /// The last publish failed; positions are retried.
  final bool connectionLost;
  final LocationFix? lastFix;
  final DateTime? lastPublishedAt;

  /// One-off message for a snackbar; [messageId] changes with each one.
  final String? message;
  final int messageId;

  TrackingSession? get pendingRequest =>
      session?.status == TrackingStatus.pending ? session : null;

  bool get isActive => session?.status == TrackingStatus.active;

  /// Active on the server but this device isn't publishing (permission
  /// revoked, app restarted without access, or another device).
  bool get isPaused => isActive && !sharing;

  MyTrackingState copyWith({
    bool? loading,
    bool? busy,
    TrackingSession? session,
    bool clearSession = false,
    BranchLocation? branch,
    bool clearBranch = false,
    LocationAccess? access,
    bool? sharing,
    bool? connectionLost,
    LocationFix? lastFix,
    DateTime? lastPublishedAt,
    String? message,
    int? messageId,
  }) {
    return MyTrackingState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      session: clearSession ? null : session ?? this.session,
      branch: clearBranch ? null : branch ?? this.branch,
      access: access ?? this.access,
      sharing: sharing ?? this.sharing,
      connectionLost: connectionLost ?? this.connectionLost,
      lastFix: lastFix ?? this.lastFix,
      lastPublishedAt: lastPublishedAt ?? this.lastPublishedAt,
      message: message ?? this.message,
      messageId: messageId ?? this.messageId,
    );
  }
}

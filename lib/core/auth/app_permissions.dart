import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/core/entities/user_entity.dart';

/// Application roles, mapped from `users.role`.
enum AppRole {
  /// `Admin`: full access.
  admin,

  /// `User`: read-only; can watch live tracking.
  user,

  /// `Worker`: a technician. Works only on tickets assigned to them and
  /// shares their own location.
  technician,

  /// Unknown role or a terminated/suspended account: nothing.
  none;

  static AppRole of(UserEntity? user) {
    if (user == null || user.isDisabled) return AppRole.none;
    return switch (user.role) {
      UserEntity.adminRole => AppRole.admin,
      'User' => AppRole.user,
      'Worker' => AppRole.technician,
      _ => AppRole.none,
    };
  }
}

/// The single place the app decides what the signed-in user may do. It only
/// shapes the UI and stops pointless requests: the same rules are enforced
/// by row-level security and triggers in the database
/// (supabase/migrations/20261025185740_role_based_access.sql), so a client
/// that skips these checks is still refused.
class AppPermissions {
  AppPermissions(this.user) : role = AppRole.of(user);

  final UserEntity? user;
  final AppRole role;

  bool get isAdmin => role == AppRole.admin;
  bool get isTechnician => role == AppRole.technician;

  // Tickets & assets
  bool get canCreateTicket => isAdmin;
  bool get canDeleteTicket => isAdmin;
  bool get canCreateAsset => isAdmin;
  bool get canEditAsset => isAdmin;
  bool get canDeleteAsset => isAdmin;
  bool get canManageAccounts => isAdmin;

  bool isAssignedTo(int? engineerId) =>
      engineerId != null && user != null && BigInt.from(engineerId) == user!.id;

  /// Link assets, record repairs, edit the damage description and dates.
  bool canWorkOn(int? engineerId) =>
      isAdmin || (isTechnician && isAssignedTo(engineerId));

  /// Status changes offered for a ticket in [current] state.
  List<TicketStatus> statusChangesFor(TicketStatus current, int? engineerId) {
    if (current != TicketStatus.awaiting) return const [];
    if (isAdmin) return const [TicketStatus.canceled, TicketStatus.completed];
    if (isTechnician && isAssignedTo(engineerId)) {
      return const [TicketStatus.rejected, TicketStatus.completed];
    }
    return const [];
  }

  bool canSetStatus(TicketStatus current, TicketStatus next, int? engineerId) =>
      statusChangesFor(current, engineerId).contains(next);

  // Live tracking
  /// See workers and their live locations.
  bool get canViewTracking => isAdmin || role == AppRole.user;

  /// Request, cancel or stop someone else's location sharing.
  bool get canControlTracking => isAdmin;

  /// Share one's own location.
  bool get canShareLocation => isTechnician;
}

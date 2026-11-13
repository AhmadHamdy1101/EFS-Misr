import 'package:efs_misr/core/entities/positions_entity.dart';

class UserEntity {
  final BigInt id;
  final String userid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;
  final int status;
  final PositionsEntity? position;
  final String companyEmail;
  final String company;
  final String image;

  /// `users.role` value of administrators. The database checks the same
  /// value in `is_admin()`; the app uses it only to choose screens.
  static const adminRole = 'Admin';

  bool get isAdmin => role == adminRole;

  /// `users.status` 3 = Terminated, 4 = Suspended: the account may not be
  /// used. The auth user is also banned by the `update-user` function.
  static bool isDisabledStatus(int status) => status == 3 || status == 4;

  bool get isDisabled => isDisabledStatus(status);

  UserEntity({
    required this.userid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.status,
    required this.position,
    required this.companyEmail,
    required this.company,
    required this.image,
    required this.id,
  });
}

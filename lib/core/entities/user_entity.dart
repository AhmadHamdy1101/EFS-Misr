import 'package:efs_misr/core/entities/positions_entity.dart';

class UserEntity {
  final String userid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;
  final int status;
  final PositionsEntity position;
  final String companyEmail;
  final String company;
  final String image;

  UserEntity({
    required this.userid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.status,
    required this.position, required this.companyEmail, required this.company, required this.image,
});
}
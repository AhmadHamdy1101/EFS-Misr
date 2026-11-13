import 'package:efs_misr/core/entities/branch_entity.dart';

class AssetsEntity {
  final int id;
  final String type;
  final String branchName;
  final  BranchEntity branchObject;
  final String barCode;

  final String place;
  final String area;
  final num totalAmount;
  final String name;
  final String floor;

  AssetsEntity({
    required this.id,
    required this.type,
    required this.branchName,
    required this.barCode, required this.place, required this.totalAmount, required this.area, required this.branchObject,
    this.name = '',
    this.floor = '',
  });

}

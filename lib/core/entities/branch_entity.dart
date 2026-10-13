class BranchEntity {
  final int id;
  final int? branchId;
  final String name;
  final int areaId;
  final String? areaName;

  BranchEntity({
    required this.name,
    required this.id,
    required this.areaId,
    this.branchId,
    this.areaName,
  });
}

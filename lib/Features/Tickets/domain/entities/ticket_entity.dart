import 'package:efs_misr/core/entities/branch_entity.dart';
import 'package:efs_misr/core/entities/user_entity.dart';

enum TicketStatus {
  awaiting('Awaiting'),
  completed('Completed'),
  canceled('Canceled'),
  rejected('Rejected'),
  unknown('Unknown');

  const TicketStatus(this.databaseValue);

  final String databaseValue;

  static TicketStatus fromDatabase(String? value) {
    for (final status in values) {
      if (status.databaseValue.toLowerCase() == value?.toLowerCase()) {
        return status;
      }
    }
    return TicketStatus.unknown;
  }
}

class TicketEntity {
  final int id;
  final int? oricalID;
  final BranchEntity? branchEntity;
  final DateTime? requestDate;
  final DateTime? repairDate;
  final DateTime? responseDate;
  final DateTime? repairDuration;
  final DateTime? createdAt;
  final String priority;
  final int? engineer;
  final int? closedBy;
  final num amount;
  final String damageDescription;
  final String attachment;
  final String comment;
  final TicketStatus status;
  final String variation;
  final UserEntity? engineerUserEntity;
  final UserEntity? closedByUserEntity;

  const TicketEntity({
    required this.id,
    required this.oricalID,
    required this.requestDate,
    required this.repairDate,
    required this.responseDate,
    required this.repairDuration,
    required this.createdAt,
    required this.priority,
    required this.engineer,
    required this.closedBy,
    required this.amount,
    required this.damageDescription,
    required this.attachment,
    required this.comment,
    required this.status,
    required this.variation,
    required this.branchEntity,
    required this.engineerUserEntity,
    required this.closedByUserEntity,
  });
}

import '../../domain/entities/ticket_entity.dart';
import '../../../../core/models/tickets.dart';

extension TicketMapper on Tickets {
  TicketEntity toEntity() {
    return TicketEntity(
      id: id.toInt(),
      oricalID: orecalId?.toInt(),
      branchEntity: branchObject?.toBranchEntity(),
      requestDate: requestDate,
      repairDate: repairDate,
      responseDate: responseDate,
      repairDuration: repairDuration,
      createdAt: createdAt,
      priority: priority ?? '',
      engineer: engineer?.toInt(),
      closedBy: closedBy?.toInt(),
      amount: amount ?? 0,
      damageDescription: damageDescription ?? '',
      attachment: attachment ?? '',
      comment: comment ?? '',
      status: TicketStatus.fromDatabase(status),
      variation: variation ?? '',
      engineerUserEntity: user?.toUserEntity(),
      closedByUserEntity: closedByUser?.toUserEntity(),
    );
  }
}

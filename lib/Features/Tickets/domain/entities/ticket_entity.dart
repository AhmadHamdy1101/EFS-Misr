class TicketEntity {
  final int id;
  final int orecalId;
  final String branch;

  // final Branch? branchObject;
  final DateTime requestDate;
  final DateTime repairDate;
  final DateTime responseDate;
  final DateTime repairDuration;
  final String priority;
  final int engineer;
  final int closedBy;
  final int amount;
  final String damageDescription;
  final String attachment;
  final String comment;
  final String status;
  final String variation;
  final DateTime createdAt;

  // final Users? user;

  TicketEntity({
    required this.id,
    required this.orecalId,
    required this.branch,
    required this.requestDate,
    required this.repairDate,
    required this.responseDate,
    required this.repairDuration,
    required this.priority,
    required this.engineer,
    required this.closedBy,
    required this.amount,
    required this.damageDescription,
    required this.attachment,
    required this.comment,
    required this.status,
    required this.variation,
    required this.createdAt,
  });

}

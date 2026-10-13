import '../../../Tickets/domain/entities/ticket_entity.dart';

/// A spare-part or repair-cost record attached to one asset and one ticket.
class AssetRepairEntity {
  final BigInt id;
  final DateTime createdAt;
  final BigInt? assetId;
  final BigInt? ticketId;
  final num? amount;
  final String? comment;
  final String? variation;
  final TicketEntity? ticket;

  const AssetRepairEntity({
    required this.id,
    required this.createdAt,
    this.assetId,
    this.ticketId,
    this.amount,
    this.comment,
    this.variation,
    this.ticket,
  });
}

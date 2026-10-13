import '../../domain/entities/ticket_lookup_option.dart';

class TicketLookupModel {
  final int id;
  final String name;

  const TicketLookupModel({required this.id, required this.name});

  factory TicketLookupModel.fromJson(Map<String, dynamic> json) {
    return TicketLookupModel(
      id: int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
    );
  }

  TicketLookupOption toEntity() => TicketLookupOption(id: id, name: name);
}

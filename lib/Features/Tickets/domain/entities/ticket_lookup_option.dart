class TicketLookupOption {
  final int id;
  final String name;

  const TicketLookupOption({required this.id, required this.name});
}

class TicketFormOptions {
  final List<TicketLookupOption> branches;
  final List<TicketLookupOption> engineers;

  const TicketFormOptions({required this.branches, required this.engineers});
}

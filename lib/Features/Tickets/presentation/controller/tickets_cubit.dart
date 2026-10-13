import 'dart:async';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_change.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_entity.dart';
import 'package:efs_misr/Features/Tickets/domain/entities/ticket_lookup_option.dart';
import 'package:efs_misr/Features/Tickets/domain/repo/tickets_repo.dart';
import 'package:efs_misr/core/Errors/failure.dart';
import 'package:efs_misr/core/Functions/convert_to_excel_function.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit({required this.ticketsRepo}) : super(HomeInitial()) {
    _subscribeToTicketChanges();
  }

  final TicketsRepo ticketsRepo;
  final List<TicketEntity> _allTickets = [];
  final List<TicketChange> _pendingChanges = [];
  StreamSubscription<TicketChange>? _ticketChangesSubscription;
  bool _hasLoadedTickets = false;
  String _searchQuery = '';
  int? _areaFilter;
  int? _branchFilter;

  List<TicketEntity> get allTickets => List.unmodifiable(_allTickets);
  int? get selectedAreaId => _areaFilter;
  int? get selectedBranchId => _branchFilter;

  List<TicketLookupOption> get areaOptions {
    final options = <int, TicketLookupOption>{};
    for (final ticket in _allTickets) {
      final branch = ticket.branchEntity;
      if (branch != null) {
        options.putIfAbsent(
          branch.areaId,
          () => TicketLookupOption(
            id: branch.areaId,
            name: branch.areaName ?? 'Area ${branch.areaId}',
          ),
        );
      }
    }
    return _sortedOptions(options.values);
  }

  List<TicketLookupOption> get branchOptions {
    final options = <int, TicketLookupOption>{};
    for (final ticket in _allTickets) {
      final branch = ticket.branchEntity;
      if (branch != null) {
        options.putIfAbsent(
          branch.id,
          () => TicketLookupOption(id: branch.id, name: branch.name),
        );
      }
    }
    return _sortedOptions(options.values);
  }

  Future<void> getTickets() async {
    if (!_hasLoadedTickets) emit(GetTicketsLoading());
    final result = await ticketsRepo.getTickets();
    result.fold(
      (failure) {
        if (!_hasLoadedTickets) {
          emit(GetTicketsFailure(errMsg: failure.message));
        }
      },
      (tickets) {
        _allTickets
          ..clear()
          ..addAll(tickets);
        _sortTickets();
        _hasLoadedTickets = true;
        for (final change in List<TicketChange>.of(_pendingChanges)) {
          _applyChange(change);
        }
        _pendingChanges.clear();
        _emitVisibleTickets();
      },
    );
  }

  void searchTickets(String? search) {
    _searchQuery = search?.trim().toLowerCase() ?? '';
    _emitVisibleTickets();
  }

  void filterTickets({int? area, int? branch}) {
    _areaFilter = area;
    _branchFilter = branch;
    _emitVisibleTickets();
  }

  Future<Either<Failure, TicketFormOptions>> getTicketFormOptions() {
    return ticketsRepo.getTicketFormOptions();
  }

  Future<Either<Failure, ExcelExportStatus>> convertTicketsToExcel() async {
    try {
      final data = _allTickets.map((ticket) {
        return <String, dynamic>{
          'orecal_id': ticket.oricalID,
          'branch': {
            'name': ticket.branchEntity?.name,
            'branch_id': ticket.branchEntity?.branchId,
          },
          'priority': ticket.priority,
          'request_date': ticket.requestDate?.toIso8601String(),
          'repair_date': ticket.repairDate?.toIso8601String(),
          'response_date': ticket.responseDate?.toIso8601String(),
          'damage_description': ticket.damageDescription,
          'status': ticket.status.databaseValue,
        };
      }).toList();
      final status = await convertDataToExcel(data);
      return Right(status);
    } catch (error) {
      return Left(Failure.fromException(error));
    }
  }

  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required int ticketId,
    required TicketStatus status,
    DateTime? repairDate,
  }) async {
    final result = await ticketsRepo.updateTicketStatus(
      ticketId: BigInt.from(ticketId),
      status: status,
      repairDate: status == TicketStatus.completed
          ? (repairDate ?? DateTime.now())
          : null,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> updateDamageDescription({
    required int ticketId,
    required String damageDescription,
  }) async {
    final result = await ticketsRepo.updateDamageDescription(
      ticketId: BigInt.from(ticketId),
      damageDescription: damageDescription,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> updateTicketResponseDate({
    required int ticketId,
    required DateTime responseDate,
  }) async {
    final result = await ticketsRepo.updateTicketResponseDate(
      ticketId: BigInt.from(ticketId),
      responseDate: responseDate,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, TicketEntity>> addTicket({
    required BigInt oracleId,
    required String comment,
    required BigInt branchId,
    required String priority,
    required DateTime requestDate,
    required BigInt engineerId,
  }) async {
    if (oracleId <= BigInt.zero ||
        branchId <= BigInt.zero ||
        engineerId <= BigInt.zero) {
      return Left(
        GeneralFailure(
          'Select a branch and engineer and enter a valid Oracle ID.',
        ),
      );
    }
    if (comment.trim().isEmpty) {
      return Left(GeneralFailure('Comment is required.'));
    }
    final result = await ticketsRepo.addTicket(
      oracleId: oracleId,
      comment: comment,
      branchId: branchId,
      priority: priority,
      requestDate: requestDate,
      engineerId: engineerId,
    );
    result.fold((_) {}, _upsertTicket);
    return result;
  }

  Future<Either<Failure, Unit>> deleteTicket({required int ticketId}) async {
    final result = await ticketsRepo.deleteTicket(
      ticketId: BigInt.from(ticketId),
    );
    result.fold((_) {}, (_) {
      _allTickets.removeWhere((ticket) => ticket.id == ticketId);
      _emitVisibleTickets();
    });
    return result;
  }

  void _subscribeToTicketChanges() {
    try {
      _ticketChangesSubscription = ticketsRepo.watchTicketChanges().listen(
        (change) {
          if (_hasLoadedTickets) {
            _applyChange(change);
          } else {
            _pendingChanges.add(change);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Ticket realtime subscription failed.',
            error: error,
            stackTrace: stackTrace,
            name: 'TicketsCubit',
          );
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Could not start ticket realtime subscription.',
        error: error,
        stackTrace: stackTrace,
        name: 'TicketsCubit',
      );
    }
  }

  void _applyChange(TicketChange change) {
    if (change.ticket == null) {
      _allTickets.removeWhere((ticket) => ticket.id == change.id);
    } else {
      _upsertTicket(change.ticket!);
      return;
    }
    _emitVisibleTickets();
  }

  void _upsertTicket(TicketEntity ticket) {
    final index = _allTickets.indexWhere((current) => current.id == ticket.id);
    if (index == -1) {
      _allTickets.add(ticket);
    } else {
      _allTickets[index] = ticket;
    }
    _sortTickets();
    _emitVisibleTickets();
  }

  void _sortTickets() {
    _allTickets.sort((first, second) {
      final firstCreated =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondCreated =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondCreated.compareTo(firstCreated);
    });
  }

  void _emitVisibleTickets() {
    if (isClosed || !_hasLoadedTickets) return;
    final visible = _allTickets.where(_matchesFilters).toList(growable: false);
    emit(
      GetTicketsSuccess(
        tickets: List.unmodifiable(visible),
        allTickets: List.unmodifiable(_allTickets),
      ),
    );
  }

  bool _matchesFilters(TicketEntity ticket) {
    final branch = ticket.branchEntity;
    if (_areaFilter != null && branch?.areaId != _areaFilter) return false;
    if (_branchFilter != null && branch?.id != _branchFilter) return false;
    if (_searchQuery.isEmpty) return true;

    return (ticket.oricalID?.toString().toLowerCase().contains(_searchQuery) ??
            false) ||
        ticket.comment.toLowerCase().contains(_searchQuery) ||
        ticket.damageDescription.toLowerCase().contains(_searchQuery) ||
        ticket.status.databaseValue.toLowerCase().contains(_searchQuery) ||
        (branch?.name.toLowerCase().contains(_searchQuery) ?? false) ||
        (branch?.areaName?.toLowerCase().contains(_searchQuery) ?? false);
  }

  List<TicketLookupOption> _sortedOptions(Iterable<TicketLookupOption> items) {
    final options = items.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return List.unmodifiable(options);
  }

  @override
  Future<void> close() async {
    await _ticketChangesSubscription?.cancel();
    await super.close();
  }
}

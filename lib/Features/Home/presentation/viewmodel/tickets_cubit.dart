import 'dart:typed_data';

import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

part 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  HomeRepo homeRepo;

  TicketsCubit(this.homeRepo) : super(HomeInitial());

  int totalTickets = 0;
  int totalDoneTickets = 0;
  int totalAwaitingTickets = 0;

  final List<Tickets> allTickets = [];
  final List<Tickets> searchedTickets = [];

  Future<void> getTickets() async {
    emit(GetTicketsLoading());
    final result = await homeRepo.getTickets();
    result.fold(
      (failure) {
        emit(GetTicketsFailure(errMsg: failure.message));
      },
      (tickets) {
        allTickets.clear();
        allTickets.addAll(tickets);
        totalTickets = tickets.length;
        totalDoneTickets = tickets
            .where((ticket) => ticket.status == 'Completed')
            .length;
        totalAwaitingTickets = tickets
            .where((ticket) => ticket.status == 'Awaiting')
            .length;
        emit(GetTicketsSuccess(tickets: allTickets));
      },
    );
  }

  searchTickets(String? search) {
    if (search == null || search.isEmpty) {
      emit(GetTicketsSuccess(tickets: allTickets));
      return;
    }
    searchedTickets.clear();
    final res = allTickets.where((ticket) {
      final idMatch = ticket.orecalId.toString().toLowerCase().contains(search);
      final commentMatch =
          ticket.comment?.toLowerCase().contains(search) ?? false;
      final branchName =
          ticket.branchObject?.name?.toLowerCase().contains(search) ?? false;
      final areaName =
          ticket.branchObject?.area?.toLowerCase().contains(search) ?? false;
      return idMatch || commentMatch || branchName || areaName;
    }).toList();
    searchedTickets.addAll(res);
    emit(GetTicketsSuccess(tickets: searchedTickets));
  }

  Future<void> convertTicketsToExcel() async {
    emit(ConvertTicketsToExcelLoading());

    try {
      final data = await supabaseClient.tickets.select();
      if (data.isEmpty) {
        emit(ConvertTicketsToExcelFailed());
        return;
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      final headers = data.first.keys.toList();


      final headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 14;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.backColor = '#D9E1F2';
      headerStyle.fontColor = '#000000';

      final dataStyle = workbook.styles.add('DataStyle');
      dataStyle.fontSize = 12;
      dataStyle.hAlign = xlsio.HAlignType.center;


      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i].toString());
        cell.cellStyle = headerStyle;
      }


      for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final row = data[rowIndex];
        for (var colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]]?.toString() ?? '';
          final cell = sheet.getRangeByIndex(rowIndex + 2, colIndex + 1);
          cell.setText(value);
          cell.cellStyle = dataStyle;
        }
      }


      final lastRow = data.length + 1;
      sheet.getRangeByIndex(1, 1, lastRow, headers.length).autoFitColumns();

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      await FileSaver.instance.saveFile(
        name: "tickets",
        bytes: Uint8List.fromList(bytes),
        fileExtension: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );

      emit(ConvertTicketsToExcelSuccess());
    } catch (e) {
      print(e.toString());
      emit(ConvertTicketsToExcelFailed());
    }
  }
}

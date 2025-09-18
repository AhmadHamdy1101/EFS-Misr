import 'dart:io';
import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
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
    try {
      final data = await supabaseClient.tickets.select();
      if (data.isEmpty) {
        return;
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      final headers = data.first.keys.toList();

      //  headers
      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i].toString());
      }

      //  data
      for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final row = data[rowIndex];
        for (var colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]]?.toString() ?? '';
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText(value);
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      final Uint8List fileBytes = Uint8List.fromList(bytes);

      final timestamp =
          DateTime.now();
      DateFormat('d - MMM - yyyy').format(timestamp);
      final fileName = "Tickets_$timestamp.xlsx";


      if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {

        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: fileBytes,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );

      } else if (Platform.isAndroid) {

        if (await Permission.storage.request().isDenied) {
          return;
        }

        final downloadsDir = Directory("/storage/emulated/0/Download");
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }

        final filePath = "${downloadsDir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(filePath);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Tickets Export'),
        );

      } else if (Platform.isIOS) {

        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/$fileName";

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(file.path);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Tickets Export'),
        );

      }

    } catch (e) {
Get.snackbar('Error', e.toString());

    }
  }}

import 'dart:io';

import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/Features/Home/presentation/pages/add_success_page.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final List<Users> engineers = [];

  final status = ''.obs;

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
      final data = await supabaseClient.tickets.select(
        'orecal_id,branch(name) ,comment, priority, request_date, repair_date,response_date,repair_duration,users!tickets_closed_by_fkey(name)as closed_by, users!tickets_engineer_fkey(name)as engineer,damage_description,status,created_at',
      );
      if (data.isEmpty) {
        return;
      }

      final combined = data.map((row) {
        return {
          'orecal_id': row['orecal_id'],
          'branch': row['branch']?['name'] ?? '',
          'comment': row['comment'],
          'priority': row['priority'],
          'request_date': row['request_date'],
          'repair_date': row['repair_date'],
          'response_date': row['response_date'],
          'repair_duration': row['repair_duration'],
          'closed_by': row['closed_by']?['name'] ?? '',
          'engineer': row['engineer']?['name'] ?? '',
          'damage_description': row['damage_description'],
          'status': row['status'],
          'created_at': row['created_at'],
        };
      }).toList();

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      final headers = combined.first.keys.toList();
      final headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 14;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.backColor = '#008C43';
      headerStyle.fontColor = '#ffffff';

      //  headers
      for (var i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i].toString());
      }

      //  data
      for (var rowIndex = 0; rowIndex < combined.length; rowIndex++) {
        final row = combined[rowIndex];
        for (var colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]]?.toString() ?? '';
          sheet.getRangeByIndex(rowIndex + 2, colIndex + 1).setText(value);
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      final Uint8List fileBytes = Uint8List.fromList(bytes);

      final timestamp = DateTime.now();
      DateFormat('d - MMM - yyyy').format(timestamp);
      final fileName = "Tickets_$timestamp.xlsx";

      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: fileBytes,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );
      } else if (Platform.isAndroid) {
        if (await Permission.storage.request().isDenied) {
          return;
        } else {}

        final downloadsDir = await getExternalStorageDirectory();
        if (!downloadsDir!.existsSync()) {
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
      print(e);
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> updateTicketStatus(String ticketId, String newStatus) async {
    final result = await homeRepo.updateTicketStatus(
      ticketID: ticketId,
      newStatus: newStatus,
    );
    result.fold((l) {}, (r) {
      status.value = r.status!;
    });
  }

  Future<void> addTicket({
    required BigInt orecalID,
    required String comment,
    required BigInt branchID,
    required String priority,
    required DateTime requestDate,
    required BigInt engineer,
  }) async {
    final result = await homeRepo.addTicket(
      orecalID: orecalID,
      comment: comment,
      branchID: branchID,
      priority: priority,
      requestDate: requestDate,
      engineer: engineer,
    );
    result.fold(
      (l) {
        Get.snackbar(
          "Error",
          l.message,
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
      },
      (tickets) {
        // Get.snackbar(
        //   "Success",
        //   "Ticket added successfully",
        //   backgroundColor: Colors.green,
        //   colorText: AppColors.white,
        // );
        getTickets();
        Get.to(AddSuccessPage(message: 'Ticket added successfully'));
        emit(GetTicketsSuccess(tickets: allTickets));
      },
    );
  }


}

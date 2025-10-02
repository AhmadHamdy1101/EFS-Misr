import 'dart:io';

import 'package:efs_misr/Features/Home/data/models/supadart_exports.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
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

import '../../../../constants/constants.dart';

part 'accounts_state.dart';

class AccountsCubit extends Cubit<AccountsState> {
  HomeRepo homeRepo;
  AccountsCubit(this.homeRepo) : super(AccountsInitial());

  final List<Users> allUsers = [];
  final List<Users> searchedUSers = [];

  Future<void> getAccounts() async {
    emit(GetAccountsLoading());
    final result = await homeRepo.getUsers();
    result.fold(
      (failure) {
        emit(GetAccountsFailed(failure.message));
      },
      (accounts) {
        allUsers.clear();
        allUsers.addAll(accounts);
        emit(GetAccountsSuccess(allUsers));
      },
    );
  }

  searchUsers(String? search) {
    if (search == null || search.isEmpty) {
      emit(GetAccountsSuccess(allUsers));
      return;
    }
    searchedUSers.clear();
    final res = allUsers.where((user) {
      final nameMatch = user.name?.toLowerCase().contains(search) ?? false;
      final emailMatch = user.email?.toLowerCase().contains(search) ?? false;
      final companyMatch =
          user.company?.toLowerCase().contains(search) ?? false;
      return nameMatch || emailMatch || companyMatch;
    }).toList();
    searchedUSers.addAll(res);
    emit(GetAccountsSuccess(searchedUSers));
  }

  Future<void> convertAccountsToExcel() async {
    try {
      final data = await supabaseClient.users.select();
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

      final timestamp = DateTime.now();
      DateFormat('d - MMM - yyyy').format(timestamp);
      final fileName = "Users $timestamp.xlsx";

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
          ShareParams(files: [XFile(file.path)], text: 'Users Export'),
        );
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/$fileName";

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(file.path);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Users Export'),
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> deleteAccount(
    BigInt? id,
    String? userid,
    String? username,
  ) async {
    try {
      await supabaseClient.users.delete().eq('id', id!);

      await supabaseClient.functions.invoke(
        'delete-user',
        body: {'userId': userid},
      );
      getAccounts();
      emit(GetAccountsSuccess(allUsers));
      Get.snackbar("Delete Success", 'User $username deleted successfully');
    } catch (e) {
      print(e);
    }
  }
}

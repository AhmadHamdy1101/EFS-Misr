import 'dart:io';
import 'dart:typed_data';

import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../../../constants/constants.dart';
import '../../data/models/assets.dart';
part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  HomeRepo homeRepo;

  AssetsCubit(this.homeRepo) : super(AssetsInitial());

  final List<Assets> allAssets = [];
  final List<Assets> searchedAssets = [];

  Future<void> getAssets() async {
    emit(GetAssetsLoading());
    final result = await homeRepo.getAssets();

    result.fold((failure) {
      emit(GetAssetsFailure(errMsg: failure.message));
    }, (assets) {
      allAssets.clear();
      allAssets.addAll(assets);
      emit(GetAssetsSuccess(assets: allAssets));
    },);
  }


  searchAssets(String? search) {
    if (search == null || search.isEmpty) {
      emit(GetAssetsSuccess(assets: allAssets));
      return;
    }
    searchedAssets.clear();
    final res = allAssets.where((asset) {
      final nameMatch = asset.type!.toLowerCase().contains(search);
      final branchName =
          asset.branchObject?.name?.toLowerCase().contains(search) ?? false;
      final areaName =
          asset.branchObject?.area?.toLowerCase().contains(search) ?? false;
      return nameMatch || branchName || areaName;
    }).toList();
    searchedAssets.addAll(res);
    emit(GetAssetsSuccess(assets: searchedAssets));
  }

  Future<void> convertAssetsToExcel() async {
    emit(ConvertAssetsToExcelLoading());

    try {
      final data = await supabaseClient.assets.select();
      if (data.isEmpty) {
        emit(ConvertAssetsToExcelFailed());
        return;
      }

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      final headers = data.first.keys.toList();

      // ✅ Styles
      final headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 14;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.backColor = '#D9E1F2';
      headerStyle.fontColor = '#000000';

      final dataStyle = workbook.styles.add('DataStyle');
      dataStyle.fontSize = 12;
      dataStyle.hAlign = xlsio.HAlignType.center;

      // ✅ Headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i].toString());
        cell.cellStyle = headerStyle;
      }

      // ✅ Data
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
      final Uint8List fileBytes = Uint8List.fromList(bytes);

      final timestamp =
          DateTime
              .now()
              .toIso8601String()
              .replaceAll(":", "-")
              .split(".")
              .first;
      final fileName = "assets_$timestamp.xlsx";

      // Platform Check
      if (kIsWeb || Platform.isWindows || Platform.isLinux ||
          Platform.isMacOS) {
        // Web/Desktop
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: fileBytes,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );
        print("File saved via FileSaver");
      } else if (Platform.isAndroid) {
        // 📱 Android
        if (await Permission.storage
            .request()
            .isDenied) {
          emit(ConvertAssetsToExcelFailed());
          return;
        }

        final downloadsDir = Directory("/storage/emulated/0/Download");
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }

        final filePath = "${downloadsDir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(file.path);
        print(" Saved in $filePath");
      } else if (Platform.isIOS) {
        //  iOS
        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/$fileName";

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(file.path);
        print(" Saved in $filePath");
      }

      emit(ConvertAssetsToExcelSuccess());
    } catch (e) {
      print(" Error: $e");
      emit(ConvertAssetsToExcelFailed());
    }
  }
}
import 'dart:io';

import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
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

import '../../../../constants/constants.dart';
import '../../data/models/assets.dart';

part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  HomeRepo homeRepo;

  AssetsCubit(this.homeRepo) : super(AssetsInitial());

  final List<Assets> allAssets = [];
  final List<Assets> searchedAssets = [];
  final List<Assets> filterdAssets = [];

  Future<void> getAssets() async {
    emit(GetAssetsLoading());
    final result = await homeRepo.getAssets();

    result.fold(
      (failure) {
        emit(GetAssetsFailure(errMsg: failure.message));
      },
      (assets) {
        allAssets.clear();
        allAssets.addAll(assets);
        emit(GetAssetsSuccess(assets: allAssets));
      },
    );
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
          asset.branchObject?.areaObject?.name?.toLowerCase().contains(
            search,
          ) ??
          false;
      final barcode = asset.barcode?.toLowerCase().contains(search) ?? false;
      return nameMatch || branchName || areaName || barcode;
    }).toList();
    searchedAssets.addAll(res);
    emit(GetAssetsSuccess(assets: searchedAssets));
  }

  // Future<void> convertAssetsToExcel() async {
  //   try {
  //     // final data = await supabaseClient.assets.select('id,barcode,name,branch(name),floor,place,created_at,area,type,amount');
  //     final data = await supabaseClient.assetsAndTickets.select(
  //       'id,tickets(orecal_id),assets(barcode,name,branch(name),floor,place,area,type),Ammount',
  //     );
  //     if (data.isEmpty) {
  //       return;
  //     }
  //
  //     final combined = data.map((row) {
  //       return {
  //         'id': row['id'],
  //         'barcode': row['assets']?['barcode'] ?? '',
  //         'name': row['assets']?['name'] ?? '',
  //         'branch': row['assets']?['branch']?['name'] ?? '',
  //         'floor': row['assets']?['floor'] ?? '',
  //         'place': row['assets']?['place'] ?? '',
  //         'area': row['assets']?['area'] ?? '',
  //         'type': row['assets']?['type'] ?? '',
  //         'amount': row['Ammount'],
  //       };
  //     }).toList();
  //
  //     final workbook = xlsio.Workbook();
  //     final sheet = workbook.worksheets[0];
  //
  //     final headers = combined.first.keys.toList();
  //
  //     final headerStyle = workbook.styles.add('HeaderStyle');
  //     headerStyle.bold = true;
  //     headerStyle.fontSize = 14;
  //     headerStyle.hAlign = xlsio.HAlignType.center;
  //     headerStyle.backColor = '#008C43';
  //     headerStyle.fontColor = '#ffffff';
  //
  //     for (var i = 0; i < headers.length; i++) {
  //       final cell = sheet.getRangeByIndex(1, i + 1);
  //       cell.setText(headers[i].toString());
  //       cell.cellStyle = headerStyle;
  //     }
  //
  //     for (var rowIndex = 0; rowIndex < combined.length; rowIndex++) {
  //       final row = combined[rowIndex];
  //       for (var colIndex = 0; colIndex < headers.length; colIndex++) {
  //         final value = row[headers[colIndex]]?.toString() ?? '';
  //         final cell = sheet.getRangeByIndex(rowIndex + 2, colIndex + 1);
  //         cell.setText(value);
  //       }
  //     }
  //
  //     final lastRow = data.length + 1;
  //     sheet.getRangeByIndex(1, 1, lastRow, headers.length).autoFitColumns();
  //
  //     final List<int> bytes = workbook.saveAsStream();
  //     workbook.dispose();
  //
  //     final Uint8List fileBytes = Uint8List.fromList(bytes);
  //
  //     final timestamp = DateTime.now();
  //     DateFormat('d - MMM - yyyy').format(timestamp);
  //     final fileName = "Assets $timestamp.xlsx";
  //
  //     // Platform Check
  //     if (kIsWeb ||
  //         Platform.isWindows ||
  //         Platform.isLinux ||
  //         Platform.isMacOS) {
  //       await FileSaver.instance.saveFile(
  //         name: fileName,
  //         bytes: fileBytes,
  //         fileExtension: "xlsx",
  //         mimeType: MimeType.microsoftExcel,
  //       );
  //     } else if (Platform.isAndroid) {
  //       if (await Permission.storage.request().isDenied) {
  //         return;
  //       }
  //       if (await Permission.storage.request().isDenied) {
  //         return;
  //       }
  //
  //       final downloadsDir = await getExternalStorageDirectory();
  //       if (!downloadsDir!.existsSync()) {
  //         downloadsDir.createSync(recursive: true);
  //       }
  //       final filePath = "${downloadsDir.path}/$fileName";
  //       final file = File(filePath);
  //       await file.writeAsBytes(fileBytes);
  //       await OpenFilex.open(filePath);
  //       await SharePlus.instance.share(
  //         ShareParams(files: [XFile(file.path)], text: 'Assets Export'),
  //       );
  //     } else if (Platform.isIOS) {
  //       final dir = await getApplicationDocumentsDirectory();
  //       final filePath = "${dir.path}/$fileName";
  //
  //       final file = File(filePath);
  //       await file.writeAsBytes(fileBytes);
  //
  //       await OpenFilex.open(file.path);
  //       await SharePlus.instance.share(
  //         ShareParams(files: [XFile(file.path)], text: 'Assets Export'),
  //       );
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  Future<void> convertAssetsToExcel() async {
    try {
      // ---------------- Fetch Data ----------------
      final data = await supabaseClient.assetsAndTickets.select(
        'id,tickets(orecal_id),assets(barcode,name,branch(name,area(name)),floor,place,type),Ammount',
      );

      if (data.isEmpty) {
        print("No data to export");
        return;
      }

      final combined = data.map((row) {
        return {
          'id': row['id'],
          'barcode': row['assets']?['barcode'] ?? '',
          'name': row['assets']?['name'] ?? '',
          'branch': row['assets']?['branch']?['name'] ?? '',
          'floor': row['assets']?['floor'] ?? '',
          'place': row['assets']?['place'] ?? '',
          'area': row['assets']?['branch']?['area']?['name']  ?? '',
          'type': row['assets']?['type'] ?? '',
          'amount': row['Ammount'] ?? '',
        };
      }).toList();

      // ---------------- Create Excel ----------------
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      final headers = combined.first.keys.toList();

      // Header style
      final headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.fontSize = 14;
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.backColor = '#008C43';
      headerStyle.fontColor = '#ffffff';

      // Headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i].toUpperCase());
        cell.cellStyle = headerStyle;
      }

      // Data rows
      for (var rowIndex = 0; rowIndex < combined.length; rowIndex++) {
        final row = combined[rowIndex];
        for (var colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]]?.toString() ?? '';
          final cell = sheet.getRangeByIndex(rowIndex + 2, colIndex + 1);
          cell.setText(value);
        }
      }

      // Auto-fit columns
      final lastRow = data.length + 1;
      sheet.getRangeByIndex(1, 1, lastRow, headers.length).autoFitColumns();

      // ---------------- Save File ----------------
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final Uint8List fileBytes = Uint8List.fromList(bytes);
      final timestamp = DateFormat('d-MMM-yyyy').format(DateTime.now());
      final fileName = "Assets-$timestamp.xlsx";

      // ---------------- Platform Handling ----------------
      if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // ---- Web/Desktop ----
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: fileBytes,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );
      }

      else if (Platform.isAndroid) {
        // ---- Android ----
        if (await Permission.storage.request().isDenied) {
          return;
        }else{}

        // استخدم مجلد التنزيلات الرسمي
        final downloadsDir = await getExternalStorageDirectory();
        if (!downloadsDir!.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }

        final filePath = "${downloadsDir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(filePath);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Assets Export'),
        );
      }

      else if (Platform.isIOS) {
        // ---- iOS ----
        final dir = await getApplicationDocumentsDirectory();
        final filePath = "${dir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await OpenFilex.open(file.path);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Assets Export'),
        );
      }

      print("✅ File exported successfully: $fileName");
    } catch (e, st) {
      print("❌ Error while exporting assets: $e");
      print(st);
    }
  }

  void filterAssets({BigInt? area, BigInt? branch}) {
    if (area == null && branch == null) {
      emit(GetAssetsSuccess(assets: allAssets));
      return;
    }
    filterdAssets.clear();

    final res = allAssets.where((asset) {
      final matchArea =
          area == null || asset.branchObject?.areaObject?.id == area;
      final matchBranch = branch == null || asset.branchObject?.id == branch;

      return matchArea && matchBranch;
    }).toList();

    filterdAssets.addAll(res);
    emit(GetAssetsSuccess(assets: filterdAssets));
  }

  Future<void> addAssetsData({
    required String? barcode,
    required String? name,
    required String? floor,
    required String? place,
    required String? type,
    required BigInt? branch,
  }) async {
    final res = await homeRepo.addAssets(
      barcode: barcode,
      name: name,
      floor: floor,
      place: place,
      type: type,
      branch: branch,
    );
    res.fold(
      (l) {
        Get.snackbar(
          'Error',
          l.message,
          backgroundColor: Colors.red,
          colorText: AppColors.white,
        );
      },
      (r) {
        getAssets();
        emit(GetAssetsSuccess(assets: allAssets));
        Get.snackbar(
          "Add Assets Success",
          'Assets Added Successfully',
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
        );
      },
    );
  }
  Future<void> deleteAsset(
      BigInt? id,
      ) async {
    try {
      await supabaseClient.assets.delete().eq('id', id!);

      getAssets();
      emit(GetAssetsSuccess(assets: allAssets));
      Get.snackbar("Delete Success", ' Asset deleted successfully');
    } catch (e) {
      print(e);
    }
  }




}

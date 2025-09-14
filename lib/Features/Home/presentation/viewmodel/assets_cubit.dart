import 'dart:typed_data';

import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../../../../constants/constants.dart';
import '../../data/models/assets.dart';
part 'assets_state.dart';

class AssetsCubit extends Cubit<AssetsState> {
  HomeRepo homeRepo;
  AssetsCubit(this.homeRepo) : super(AssetsInitial());

  final List<Assets> allAssets = [];
  final List<Assets> searchedAssets = [];

  Future<void> getAssets()async{
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
        name: "Assets",
        bytes: Uint8List.fromList(bytes),
        fileExtension: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );

      emit(ConvertAssetsToExcelSuccess());
    } catch (e) {
      print(e.toString());
      emit(ConvertAssetsToExcelFailed());
    }
  }
}


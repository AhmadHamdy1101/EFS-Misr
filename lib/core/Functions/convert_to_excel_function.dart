import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

Future<void> convertDataToExcel(List<Map<String, dynamic>> data) async {
  try {
    final combined = data.map((row) {
      return {
        'id': row['id'],
        'barcode': row['assets']?['barcode'] ?? '',
        'name': row['assets']?['name'] ?? '',
        'branch': row['assets']?['branch']?['name'] ?? '',
        'floor': row['assets']?['floor'] ?? '',
        'place': row['assets']?['place'] ?? '',
        'area': row['assets']?['area'] ?? '',
        'type': row['assets']?['type'] ?? '',
        'amount': row['Ammount'],
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

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i].toString());
      cell.cellStyle = headerStyle;
    }

    for (var rowIndex = 0; rowIndex < combined.length; rowIndex++) {
      final row = combined[rowIndex];
      for (var colIndex = 0; colIndex < headers.length; colIndex++) {
        final value = row[headers[colIndex]]?.toString() ?? '';
        final cell = sheet.getRangeByIndex(rowIndex + 2, colIndex + 1);
        cell.setText(value);
      }
    }

    final lastRow = data.length + 1;
    sheet.getRangeByIndex(1, 1, lastRow, headers.length).autoFitColumns();

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final Uint8List fileBytes = Uint8List.fromList(bytes);

    final timestamp = DateTime.now();
    DateFormat('d - MMM - yyyy').format(timestamp);
    final fileName = "Assets $timestamp.xlsx";

    // Platform Check
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
      if (await Permission.storage.request().isDenied) {
        return;
      }

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
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await OpenFilex.open(file.path);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Assets Export'),
      );
    }
  } catch (e) {
    log(e.toString());
  }
}

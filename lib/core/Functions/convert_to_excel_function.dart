import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

enum ExcelExportStatus { saved, cancelled, noData }

String excelExportStatusMessage(ExcelExportStatus status) => switch (status) {
  ExcelExportStatus.saved => 'Export completed',
  ExcelExportStatus.cancelled => 'Export cancelled',
  ExcelExportStatus.noData => 'No data to export',
};

/// Exports asset-ticket rows or ticket rows returned by Supabase to an XLSX
/// file. Export errors are allowed to reach the caller so the UI can report
/// them instead of silently treating a failed export as successful.
Future<ExcelExportStatus> convertDataToExcel(
  List<Map<String, dynamic>> data,
) async {
  if (data.isEmpty) return ExcelExportStatus.noData;

  final isTicketExport = data.first.containsKey('orecal_id');
  final rows = isTicketExport
      ? data.map(_ticketExportRow).toList()
      : data.map(_assetExportRow).toList();

  return saveRowsToExcel(
    rows,
    fileNamePrefix: isTicketExport ? 'Tickets' : 'Assets',
  );
}

/// Exports already flattened rows. This is shared by the account export so
/// platform-specific file handling stays in one place.
Future<ExcelExportStatus> saveRowsToExcel(
  List<Map<String, dynamic>> rows, {
  required String fileNamePrefix,
}) async {
  if (rows.isEmpty) return ExcelExportStatus.noData;

  final workbook = xlsio.Workbook();
  try {
    final sheet = workbook.worksheets[0];
    final headers = rows.first.keys.toList(growable: false);

    final headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.fontSize = 14;
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.backColor = '#008C43';
    headerStyle.fontColor = '#ffffff';

    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.getRangeByIndex(1, column + 1);
      cell.setText(headers[column]);
      cell.cellStyle = headerStyle;
    }

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var column = 0; column < headers.length; column++) {
        sheet
            .getRangeByIndex(rowIndex + 2, column + 1)
            .setText(row[headers[column]]?.toString() ?? '');
      }
    }

    sheet
        .getRangeByIndex(1, 1, rows.length + 1, headers.length)
        .autoFitColumns();

    final bytes = Uint8List.fromList(workbook.saveAsStream());
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final fileName = '${fileNamePrefix}_$timestamp';

    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      return ExcelExportStatus.saved;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('XLSX export is not supported on this platform.');
    }

    // Use the system document picker so the user chooses a visible location.
    // This works with Android's scoped storage without broad storage access.
    final savedPath = await FileSaver.instance.saveAs(
      name: fileName,
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
    return savedPath == null
        ? ExcelExportStatus.cancelled
        : ExcelExportStatus.saved;
  } finally {
    workbook.dispose();
  }
}

Map<String, dynamic> _assetExportRow(Map<String, dynamic> row) => {
  'id': row['id'],
  'barcode': _relationValue(row['assets'], 'barcode'),
  'name': _relationValue(row['assets'], 'name'),
  'branch': _relationValue(_relationValue(row['assets'], 'branch'), 'name'),
  'floor': _relationValue(row['assets'], 'floor'),
  'place': _relationValue(row['assets'], 'place'),
  'area': _relationValue(row['assets'], 'area'),
  'type': _relationValue(row['assets'], 'type'),
  'amount': row['Ammount'],
};

Map<String, dynamic> _ticketExportRow(Map<String, dynamic> row) => {
  'orecal_id': row['orecal_id'],
  'branch_name': _relationValue(row['branch'], 'name'),
  'branch_id': _relationValue(row['branch'], 'branch_id'),
  'damage_description': row['damage_description'],
  'priority': row['priority'],
  'request_date': row['request_date'],
  'repair_date': row['repair_date'],
  'response_date': row['response_date'],
  'status': row['status'],
};

Object? _relationValue(Object? relation, String field) {
  if (relation is Map) return relation[field];
  if (relation is List && relation.isNotEmpty && relation.first is Map) {
    return (relation.first as Map)[field];
  }
  return null;
}

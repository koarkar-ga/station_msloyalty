import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

Future<void> exportDuplicateAnalysis(List<Map<String, dynamic>> analyzedData) async {
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];
  sheet.name = 'Duplicate_Analysis';

  // Styles
  xlsio.Style headerStyle = workbook.styles.add('headerStyle');
  headerStyle.backColor = '#4472C4'; // Blue
  headerStyle.fontColor = '#FFFFFF'; // White
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;
  headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style suspiciousStyle = workbook.styles.add('suspiciousStyle');
  suspiciousStyle.backColor = '#FFC7CE'; // Light Red (Danger)
  suspiciousStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style warningStyle = workbook.styles.add('warningStyle');
  warningStyle.backColor = '#FFEB9C'; // Light Yellow (Warning)
  warningStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style normalStyle = workbook.styles.add('normalStyle');
  normalStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  // Title Row (တင်ပြချက်)
  final xlsio.Range titleRange = sheet.getRangeByName('A1:J1');
  titleRange.merge();
  titleRange.setText('Duplicate Vehicle Analysis Report (တင်ပြချက်)');
  titleRange.cellStyle.fontSize = 14;
  titleRange.cellStyle.bold = true;
  titleRange.cellStyle.hAlign = xlsio.HAlignType.center;
  titleRange.cellStyle.vAlign = xlsio.VAlignType.center;
  titleRange.cellStyle.backColor = '#4472C4';
  titleRange.cellStyle.fontColor = '#FFFFFF';

  // Header (Row 2 now)
  final headers = [
    "Sr", "Station Name", "Date & Time", "Vehicle No", "Voucher No", 
    "Fuel Type", "Liter", "Amount", "Time Interval (Interval)", "Analysis Reason"
  ];
  for (int i = 0; i < headers.length; i++) {
    var cell = sheet.getRangeByIndex(2, i + 1);
    cell.setText(headers[i]);
    cell.cellStyle = headerStyle;
  }

  // Data (Start from Row 3)
  for (int i = 0; i < analyzedData.length; i++) {
    final row = analyzedData[i];
    final rowIndex = i + 3;
    final isSuspicious = row['is_suspicious'] == true;

    final values = [
      "${i + 1}",
      "${row['station_name']} (${row['station_id']})",
      row['S_Date'] ?? '-',
      row['Vehical_No'] ?? '-',
      row['VocNo'] ?? '-',
      row['FuelTypeName'] ?? '-',
      row['SALELITER'] ?? 0.0,
      row['TotalPrice'] ?? 0,
      row['analysis_time_diff'] ?? '-',
      row['suspicious_reason'] ?? '-',
    ];

    for (int col = 0; col < values.length; col++) {
      var cell = sheet.getRangeByIndex(rowIndex, col + 1);
      final val = values[col];
      
      if (val is num) {
        cell.setNumber(val.toDouble());
      } else {
        cell.setText(val.toString());
      }

      // Apply Conditional Formatting via Styles
      if (isSuspicious) {
         cell.cellStyle = suspiciousStyle;
      } else if (col == 8 && val != "-") { // Interval Column
         cell.cellStyle = warningStyle;
      } else {
         cell.cellStyle = normalStyle;
      }
    }
  }

  // Column Widths
  for (int i = 1; i <= headers.length; i++) {
    sheet.setColumnWidthInPixels(i, 130);
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final String fileName = "Duplicate_Analysis_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  final path = "${AppConfig.exportPath}/$fileName";
  final file = File(path);

  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }
  await file.writeAsBytes(bytes, flush: true);
  OpenFile.open(path);
}

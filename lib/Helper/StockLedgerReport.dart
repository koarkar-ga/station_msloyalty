import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

Future<void> exportStockLedgerReport(List<dynamic> queryData) async {
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];
  sheet.name = 'Stock_Ledger';

  xlsio.Style headerStyle = workbook.styles.add('headerStyle');
  headerStyle.backColor = '#D3D3D3';
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;
  headerStyle.vAlign = xlsio.VAlignType.center;
  headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style cellStyle = workbook.styles.add('cellStyle');
  cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
  cellStyle.vAlign = xlsio.VAlignType.center;
  cellStyle.numberFormat = '#,##0.0';

    List<String> headers = [
      "Sr",
      "Tank No",
      "Tank Name",
      "Fuel Type",
      "Capacity",
      "Opening",
      "Received (L)",
      "Received (G)",
      "Sale",
      "Adjust",
      "Mobile",
      "Closing",
      "Tank Balance",
      "Gain/Loss",
    ];

    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < queryData.length; i++) {
      var row = queryData[i];
      int rowIndex = i + 2;

      double receivedL = (row['received'] ?? 0.0).toDouble();
      double receivedG = receivedL / 4.546;

      final values = [
        "${i + 1}",
        row['Tank_No'] ?? '-',
        row['Tank_Name'] ?? '-',
        row['FuelTypeName'] ?? '-',
        row['Capacity'] ?? 0.0,
        row['opening'] ?? 0.0,
        receivedL,
        receivedG,
        row['sale'] ?? 0.0,
        row['adjust'] ?? 0.0,
        row['mobile'] ?? 0.0,
        row['closing'] ?? 0.0,
        row['tankbalance'] ?? 0.0,
        row['Gain_Mine'] ?? 0.0,
      ];

    for (int col = 0; col < values.length; col++) {
      var cell = sheet.getRangeByIndex(rowIndex, col + 1);
      var val = values[col];

      if (val is num) {
        cell.setNumber(val.toDouble());
      } else {
        cell.setText(val.toString());
      }
      cell.cellStyle = cellStyle;
    }
  }

  for (int i = 1; i <= headers.length; i++) {
    sheet.setColumnWidthInPixels(i, 110);
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final String fileName = "StockLedger_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  final path = "${AppConfig.exportPath}/$fileName";

  final file = File(path);

  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }

  await file.writeAsBytes(bytes, flush: true);
  OpenFile.open(path);
}

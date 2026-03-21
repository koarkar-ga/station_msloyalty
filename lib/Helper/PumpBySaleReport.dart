import 'dart:io';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:open_file/open_file.dart';

// Helper Class to store summary data
class SaleDataSummary {
  double totalLiter = 0;
  double totalAmount = 0;
  double price = 0;

  void add(double liter, double amount, double currentPrice) {
    totalLiter += liter;
    totalAmount += amount;
    // Price က အမြဲပြောင်းလဲနိုင်ပေမယ့် Report မှာ နောက်ဆုံးစျေး (သို့) Average ကို ပြလေ့ရှိပါတယ်
    // ဒီမှာတော့ နောက်ဆုံးဝင်လာတဲ့ Price ကို ယူထားပါတယ်
    price = currentPrice;
  }
}

Future<void> exportSaleDataReport(
  List<dynamic> rawData,
  String stationName,
  String startDate,
  String endDate,
) async {
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];
  // Function ရဲ့ အပေါ်မှာ Summary Map တစ်ခု ကြေညာပါ
  Map<String, double> saleTypeSummary = {};

  // --- 1. Styles ---
  xlsio.Style headerStyle = workbook.styles.add('headerStyle');
  headerStyle.backColor = '#D9E1F2';
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;
  headerStyle.vAlign = xlsio.VAlignType.center;
  headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style cellStyle = workbook.styles.add('cellStyle');
  cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
  cellStyle.vAlign = xlsio.VAlignType.center;

  xlsio.Style totalStyle = workbook.styles.add('totalStyle');
  totalStyle.fontColor = '#FF0000'; // Total Row အနီရောင်
  totalStyle.bold = true;
  totalStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  // --- 2. Header Setup ---
  sheet.getRangeByName('A1:I1').merge();
  sheet.getRangeByName('A1').setText('MOONSUN ($stationName)');
  sheet.getRangeByName('A1').cellStyle.hAlign = xlsio.HAlignType.center;
  sheet.getRangeByName('A1').cellStyle.bold = true;

  sheet.getRangeByName('A2:I2').merge();
  sheet.getRangeByName('A2').setText('Pump Sale by Sale Type');
  sheet.getRangeByName('A2').cellStyle.hAlign = xlsio.HAlignType.center;

  sheet.getRangeByName('A3:I3').merge();
  sheet.getRangeByName('A3').setText('From $startDate to $endDate');
  sheet.getRangeByName('A3').cellStyle.hAlign = xlsio.HAlignType.center;

  List<String> columns = [
    'Station ID',
    'Station Name',
    'Grade',
    'Sale Type',
    'Sale Liter',
    'Liter Price',
    'Sale Gallon',
    'Sale Amount',
    'Discount',
    'C/Notes',
    'Balance Amount',
  ];
  for (int i = 0; i < columns.length; i++) {
    sheet.getRangeByIndex(4, i + 1).setText(columns[i]);
    sheet.getRangeByIndex(4, i + 1).cellStyle = headerStyle;
  }

  // --- 3. Data Grouping Logic ---
  // Structure: Map<StationKey, Map<Grade, Map<SaleType, DataSummary>>>
  // StationKey will be a combination to keep its info
  Map<String, Map<String, Map<String, SaleDataSummary>>> groupedData = {};
  Map<String, Map<String, String>> stationInfo = {}; // Map<StationKey, Map<attr, value>>

  for (var row in rawData) {
    String sId = row['station_id'] ?? '-';
    String sName = row['station_name'] ?? '-';
    String sKey = "${sId}_$sName";
    String grade = row['FuelTypeName'] ?? 'Unknown';
    String saleType = row['Sale_Type_name'] ?? 'Cash Sale';
    double liter = double.tryParse(row['SALELITER']?.toStringAsFixed(4) ?? '0') ?? 0;
    double amount = double.tryParse(row['TotalPrice']?.toStringAsFixed(2) ?? '0') ?? 0;
    double price = double.tryParse(row['TodayPrice']?.toStringAsFixed(2) ?? '0') ?? 0;

    if (!stationInfo.containsKey(sKey)) {
      stationInfo[sKey] = {'id': sId, 'name': sName};
    }
    if (!groupedData.containsKey(sKey)) {
      groupedData[sKey] = {};
    }
    if (!groupedData[sKey]!.containsKey(grade)) {
      groupedData[sKey]![grade] = {};
    }
    if (!groupedData[sKey]![grade]!.containsKey(saleType)) {
      groupedData[sKey]![grade]![saleType] = SaleDataSummary();
    }
    groupedData[sKey]![grade]![saleType]!.add(liter, amount, price);
  }

  // --- 4. Excel Writing Loop ---
  int currentRow = 5;
  double grandTotalLiter = 0;
  double grandTotalGallon = 0;
  double grandTotalAmount = 0;

  // Station တစ်ခုချင်းစီ Loop ပတ်မည်
  for (var sKey in groupedData.keys) {
    var sId = stationInfo[sKey]!['id'];
    var sName = stationInfo[sKey]!['name'];
    Map<String, Map<String, SaleDataSummary>> gradesMap = groupedData[sKey]!;

    for (var grade in gradesMap.keys) {
      Map<String, SaleDataSummary> saleTypesMap = gradesMap[grade]!;

      double gradeTotalLiter = 0;
      double gradeTotalAmount = 0;
      double gradeTotalGallon = 0;

      for (var saleType in saleTypesMap.keys) {
        var data = saleTypesMap[saleType]!;
        double saleGallon = data.totalLiter / 4.546;

        saleTypeSummary[saleType] = (saleTypeSummary[saleType] ?? 0) + data.totalAmount;

        sheet.getRangeByIndex(currentRow, 1).setText(sId);
        sheet.getRangeByIndex(currentRow, 2).setText(sName);
        sheet.getRangeByIndex(currentRow, 3).setText(grade);
        sheet.getRangeByIndex(currentRow, 4).setText(saleType);
        sheet.getRangeByIndex(currentRow, 5).setNumber(double.parse(data.totalLiter.toStringAsFixed(3)));
        sheet.getRangeByIndex(currentRow, 6).setNumber(data.price);
        sheet.getRangeByIndex(currentRow, 6).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 6).numberFormat = '#,##0.00';

        sheet.getRangeByIndex(currentRow, 7).setNumber(double.tryParse(saleGallon.toStringAsFixed(4)) ?? 0);
        sheet.getRangeByIndex(currentRow, 7).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 7).numberFormat = '#,##0.0000';

        sheet.getRangeByIndex(currentRow, 8).setNumber(double.tryParse(data.totalAmount.toStringAsFixed(3)) ?? 0);
        sheet.getRangeByIndex(currentRow, 8).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 8).numberFormat = '#,##0.00';

        sheet.getRangeByIndex(currentRow, 9).setNumber(0);
        sheet.getRangeByIndex(currentRow, 9).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 9).numberFormat = '#,##0.00';

        sheet.getRangeByIndex(currentRow, 10).setNumber(0);
        sheet.getRangeByIndex(currentRow, 10).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 10).numberFormat = '#,##0.00';

        sheet.getRangeByIndex(currentRow, 11).setNumber(double.tryParse(data.totalAmount.toStringAsFixed(3)) ?? 0);
        sheet.getRangeByIndex(currentRow, 11).cellStyle.hAlign = xlsio.HAlignType.right;
        sheet.getRangeByIndex(currentRow, 11).numberFormat = '#,##0.00';

        for (int i = 1; i <= 11; i++) {
          sheet.getRangeByIndex(currentRow, i).cellStyle = cellStyle;
        }

        currentRow++;
        gradeTotalLiter += data.totalLiter;
        gradeTotalAmount += data.totalAmount;
        gradeTotalGallon += saleGallon;
      }

      // === Grade Total Row ===
      sheet.getRangeByIndex(currentRow, 4).setText('TOTAL');
      sheet.getRangeByIndex(currentRow, 5).setNumber(double.parse(gradeTotalLiter.toStringAsFixed(3)));
      sheet.getRangeByIndex(currentRow, 7).setNumber(double.parse(gradeTotalGallon.toStringAsFixed(4)));
      sheet.getRangeByIndex(currentRow, 8).setNumber(gradeTotalAmount);
      sheet.getRangeByIndex(currentRow, 8).numberFormat = '#,##0.00';
      sheet.getRangeByIndex(currentRow, 11).setNumber(gradeTotalAmount);
      sheet.getRangeByIndex(currentRow, 11).numberFormat = '#,##0.00';

      for (int i = 1; i <= 11; i++) {
        sheet.getRangeByIndex(currentRow, i).cellStyle = totalStyle;
      }
      currentRow++;

      grandTotalLiter += gradeTotalLiter;
      grandTotalAmount += gradeTotalAmount;
      grandTotalGallon += gradeTotalGallon;
    }
  }

  // ၁။ Grand Total ပြီးနောက် ၂ ကြောင်းမြောက်မှာ စရေးမယ်
  currentRow += 2;

  // ၂။ Summary Header
  sheet
      .getRangeByIndex(currentRow, 1, currentRow, 2)
      .setText("Total Sale Type Summary");
  sheet.getRangeByIndex(currentRow, 1, currentRow, 2).cellStyle.bold = true;
  sheet.getRangeByIndex(currentRow, 1, currentRow, 2).cellStyle.hAlign =
      xlsio.HAlignType.center;
  sheet.getRangeByIndex(currentRow, 1, currentRow, 9).merge();
  currentRow++;

  // ၃။ Map ထဲမှာရှိတဲ့ Sale Type တွေအကုန်လုံးကို Loop ပတ်ပြီး ထုတ်မယ်
  saleTypeSummary.forEach((typeName, totalAmount) {
    // Sale Type အမည် (ဥပမာ - Total Cash Sale)
    sheet.getRangeByIndex(currentRow, 1).setText("Total $typeName");
    sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(currentRow, 1, currentRow, 8).merge();
    sheet
            .getRangeByIndex(currentRow, 1, currentRow, 8)
            .cellStyle
            .borders
            .all
            .lineStyle =
        xlsio.LineStyle.thin;

    // Sale Amount ကို Column F (နမူနာ) မှာ ပြမည်
    var amountCell = sheet.getRangeByIndex(currentRow, 9);
    amountCell.setNumber(totalAmount);
    amountCell.numberFormat = '#,##0'; // ကော်မာ Format
    amountCell.cellStyle.hAlign = xlsio.HAlignType.right;
    amountCell.cellStyle.bold = true;
    amountCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

    // အောက်ခြေ Summary ဖြစ်လို့ စာလုံးအမဲလေး ထားနိုင်ပါတယ်
    sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    amountCell.cellStyle.bold = true;

    currentRow++;
  });

  // --- 5. GRAND TOTAL ---
  sheet.getRangeByIndex(currentRow, 1).setText('GRAND TOTAL');
  sheet.getRangeByIndex(currentRow, 1, currentRow, 4).merge();

  var totalCell = sheet.getRangeByIndex(currentRow, 5);
  totalCell.setNumber(double.parse(grandTotalLiter.toStringAsFixed(3)));
  sheet.getRangeByIndex(currentRow, 5).numberFormat = '#,##0.000';
  
  sheet
      .getRangeByIndex(currentRow, 7)
      .setNumber(double.parse(grandTotalGallon.toStringAsFixed(4)));
  sheet.getRangeByIndex(currentRow, 7).numberFormat = '#,##0.0000';

  sheet.getRangeByIndex(currentRow, 8).setNumber(grandTotalAmount);
  sheet.getRangeByIndex(currentRow, 8).numberFormat = '#,##0.00';

  sheet.getRangeByIndex(currentRow, 11).setNumber(grandTotalAmount);
  sheet.getRangeByIndex(currentRow, 11).numberFormat = '#,##0.00';

  for (int i = 1; i <= 11; i++) {
    sheet.getRangeByIndex(currentRow, i).cellStyle = totalStyle;
  }

  // Auto Fit Columns
  //sheet.getRangeByName('A1:I$currentRow').autoFitColumns();
  // Table Header (Row 4) အတွက်
  sheet.setRowHeightInPixels(4, 25);

  // Column များအတွက် (နမူနာ)
  sheet.setColumnWidthInPixels(1, 150); // Grade
  sheet.setColumnWidthInPixels(2, 120); // Sale Type
  sheet.setColumnWidthInPixels(3, 100); // Sale Liter
  sheet.setColumnWidthInPixels(5, 100); // Sale Gallon
  sheet.setColumnWidthInPixels(6, 120); // Sale Amount
  sheet.setColumnWidthInPixels(9, 120); // Balance Amount

  // --- Save File ---
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final path =
      "${AppConfig.exportPath}/SaleReport_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  final file = File(path);

  // Folder မရှိရင် ဆောက်မယ်
  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }

  print(path);
  await file.writeAsBytes(bytes, flush: true);
  OpenFile.open(path);
}

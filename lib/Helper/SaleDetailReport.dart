import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

Future<void> exportSaleDetailReport(List<Map<String, dynamic>> queryData) async {
  // ၁။ Workbook နဲ့ Worksheet အသစ်ဆောက်မယ်
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];
  sheet.name = 'Sale_Detail';

  // ၂။ Style များ သတ်မှတ်ခြင်း
  xlsio.Style headerStyle = workbook.styles.add('headerStyle');
  headerStyle.backColor = '#D3D3D3'; // မီးခိုးနုရောင်
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;
  headerStyle.vAlign = xlsio.VAlignType.center;
  headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  xlsio.Style cellStyle = workbook.styles.add('cellStyle');
  cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
  cellStyle.vAlign = xlsio.VAlignType.center;

  // ၃။ Headers သတ်မှတ်ခြင်း
  List<String> headers = [
    "Sr",
    "VocNo",
    "Date",
    "Vehical No",
    "Category",
    "Fuel Type",
    "Hose/Nozzle",
    "Pump",
    "Cashier Name",
    "Sale Gallon",
    "Sale Liter",
    "Today Price",
    "Total Price",
    "Discount",
    "T/C",
    "Balance Price",
    "Sale Form",
    "Sale Counter",
    "Credit Balance",
    "Company",
    "Pre Kyat",
    "Plus Kyat",
    "Post Kyat",
    "Debit Bal",
    "Meter Volume",
    "Meter Value",
    "Tax",
    "After Tax",
    "ePayment",
    "H/O SENDING",
  ];

  for (int i = 0; i < headers.length; i++) {
    var cell = sheet.getRangeByIndex(1, i + 1);
    cell.setText(headers[i]);
    cell.cellStyle = headerStyle;
  }

  // ၄။ Data ထည့်သွင်းခြင်း
  for (int i = 0; i < queryData.length; i++) {
    var row = queryData[i];
    int rowIndex = i + 2; // Header က Row 1 မှာမို့ Data က Row 2 ကစမယ်

    final values = [
      "${i + 1}", // Sr
      row['VocNo'] ?? '-',
      row['S_Date'] ?? '-',
      row['Vehical_No'] ?? '-',
      row['Category'] ?? '-',
      row['FuelTypeName'] ?? '-',
      "${row['PumpName'] ?? '-'} / ${row['Nozzle'] ?? '-'}",
      row['Pump'] ?? '-',
      row['CashierName'] ?? '-',
      row['SaleGallon'] ?? 0.0,
      row['SALELITER'] ?? 0.0,
      row['TodayPrice'] ?? 0,
      row['TotalPrice'] ?? 0,
      row['Discount'] ?? 0,
      row['TC'] ?? 0,
      row['BalancePrice'] ?? 0,
      row['Sale_Type_name'] ?? '-',
      row['SaleCounter'] ?? '-',
      row['CreditBalance'] ?? 0,
      row['Company'] ?? '-',
      row['PreKyat'] ?? 0,
      row['PlusKyat'] ?? 0,
      row['PostKyat'] ?? 0,
      row['DebitBal'] ?? 0,
      row['MeterVolume'] ?? 0,
      row['MeterValue'] ?? 0,
      row['Tax'] ?? 0,
      row['AfterTax'] ?? 0,
      row['ePayment'] ?? '-',
      row['HO_SENDING'] ?? 'SEND',
    ];

    for (int col = 0; col < values.length; col++) {
      var cell = sheet.getRangeByIndex(rowIndex, col + 1);
      var val = values[col];

      // ကိန်းဂဏန်းဆိုရင် Number အဖြစ် ထည့်မယ်၊ စာသားဆိုရင် Text အဖြစ် ထည့်မယ်
      if (val is num) {
        cell.setNumber(val.toDouble());
      } else {
        cell.setText(val.toString());
      }
      cell.cellStyle = cellStyle;
    }
  }

  // ၅။ Column Width များကို Auto ညှိမယ် (သို့မဟုတ်) ပုံသေ သတ်မှတ်မယ်
  for (int i = 1; i <= headers.length; i++) {
    sheet.setColumnWidthInPixels(i, 100); // Default အကျယ် ၁၀၀ ထားမယ်
  }

  // ၆။ Save & Open (သားကြီး အလိုချင်ဆုံး အပိုင်း)
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  // AppConfig မှာ exportPath ရှိတယ်ဆိုရင် အဲဒီထဲ သိမ်းမယ်
  final String fileName = "SaleDetail_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  final path = "${AppConfig.exportPath}/$fileName";

  final file = File(path);

  // Folder မရှိရင် ဆောက်မယ်
  if (!await file.parent.exists()) {
    await file.parent.create(recursive: true);
  }

  await file.writeAsBytes(bytes, flush: true);

  // ဖိုင်ကို တန်းဖွင့်မယ်
  OpenFile.open(path);
}

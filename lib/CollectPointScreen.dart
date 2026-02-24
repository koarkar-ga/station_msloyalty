import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/BuildProgessOverlay.dart';
import 'package:station_msloyalty/Helper/BuildRecentCollectedPanel.dart';
import 'package:station_msloyalty/Helper/DataCell.dart';
import 'package:station_msloyalty/Helper/FetchWithProgress.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/TextFieldDialog.dart';
import 'package:station_msloyalty/Model/BuildFuelTypeChip.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
import 'package:station_msloyalty/Model/SaleTypeModel.dart';
import 'package:station_msloyalty/Services/CheckVocNoExists.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectPointScreen extends StatefulWidget {
  const CollectPointScreen({super.key});

  @override
  State<CollectPointScreen> createState() => _CollectPointScreenState();
}

class _CollectPointScreenState extends State<CollectPointScreen> {
  List<dynamic> localDataList = [];
  //late Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchPointSales();
  }

  dispose() {
    //_timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPointSales() async {
    // ၁။ အစမှာ Loading စဖွင့်မယ်
    salesStreamController.add(SalesLoadStatus(data: [], progress: 0.0, isLoading: true));
    localDataList.clear();

    try {
      String lastRecentSalesUrl = "${AppConfig.apiUrl}/api/sales/recent";
      await fetchWithProgress(lastRecentSalesUrl, localDataList);
    } catch (e) {
      print(e.toString());
      salesStreamController.add(SalesLoadStatus(data: [], progress: 0.0, isLoading: false));
    } finally {
      salesStreamController.add(
        SalesLoadStatus(data: localDataList, progress: 1.0, isLoading: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MsAppBar(title: "Collect Point")),
      body: Row(
        children: [
          // ၁။ ဘယ်ဘက်ခြမ်း - StreamBuilder ကို Expanded အုပ်ပေးရမယ်
          Expanded(
            child: StreamBuilder<SalesLoadStatus>(
              stream: salesStreamController.stream,
              builder: (context, snapshot) {
                final status =
                    snapshot.data ?? SalesLoadStatus(data: [], progress: 0.0, isLoading: true);

                return Stack(
                  children: [
                    Column(
                      children: [
                        _buildPointHeader(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: status.data.length,
                            itemBuilder: (context, index) {
                              final sale = status.data[index];
                              return _buildDataRow(sale, index);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (status.isLoading) buildProgressOverlay(status.progress, status.data.length),

                    // ၂။ Floating Action Button ကို Left Panel ရဲ့ ညာဘက်အောက်မှာ ထားခြင်း
                    Positioned(
                      bottom: 20, // အောက်ခြေကနေ ၂၀ ခွာ
                      right: 20, // ညာဘက်ဘေး (Recent Panel မရောက်ခင်) ကနေ ၂၀ ခွာ
                      child: FloatingActionButton(
                        // သားကြီးပေးထားတဲ့ shape အတိုင်း ပြန်ထည့်ပေးထားတယ်
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white, style: BorderStyle.solid, width: 2),
                        ),
                        onPressed: () async {
                          await fetchPointSales();
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ၂။ ညာဘက်ခြမ်း - Panel (Fixed Width)
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: buildRecentCollectedPanel(), // ညာဘက် Panel
          ),
        ],
      ),
    );
  }

  Widget _buildPointHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800], // Header Background
      ),
      child: Row(
        children: [
          _headerCell("Sr", 40, isCenter: true),
          _headerCell("Voc No", 150, isCenter: true),
          _headerCell("Date", 200, isCenter: true),
          _headerCell("Fuel Type", 150, isCenter: true),
          _headerCell("Liter", 80, isCenter: true),
          _headerCell("Amount", 120, isCenter: true),
          _headerCell("Sale Type", 100, isCenter: true),

          Expanded(child: _headerCell("Status", 0, isCenter: true)),
        ],
      ),
    );
  }

  // Header Cell လေးတွေ ခဏခဏ မရေးရအောင် Helper function လေး
  Widget _headerCell(String text, double width, {bool isCenter = false}) {
    return SizedBox(
      width: width == 0 ? null : width,
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildDataRow(dynamic sale, int index) {
    // index က မ (odd) ဖြစ်ရင် အရောင်ဖျော့ဖျော့လေး တစ်ခု ထားမယ်
    final bool isEven = index % 2 == 0;

    return Container(
      // Row တစ်ခုလုံးကို အရောင်သတ်မှတ်မယ်
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.blueGrey[50], // Alternative background color
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ), // Row တစ်ခုချင်းစီရဲ့ အောက်ခြေမျဉ်း
        ),
      ),
      child: Row(
        children: [
          dataCell("${index + 1}", 40, showRightBorder: true),
          dataCell("${sale['VocNo']}", 150, showRightBorder: true),
          dataCell(
            DateFormat('dd-MM-yyyy hh:mm:ss').format(DateTime.parse(sale['S_Date'])),
            200,
            showRightBorder: true,
          ),

          // FuelType Column
          // Table Row ထဲက Fuel Type column နေရာမှာ
          dataCell(
            sale['FuelTypeName'] ?? '-',
            150, // width ကို သားကြီး စိတ်ကြိုက်ညှိပါ
            showRightBorder: true,
            cardColor: getFuelColor(sale['FuelTypeName'] ?? ''), // ဒီမှာ အရောင်လှမ်းပို့လိုက်မယ်
            alignment: Alignment.center, // Chip ပုံစံဆိုတော့ အလယ်မှာထားတာ ပိုလှတယ်
          ),

          // Liter Column (ညာဘက်ကပ် + Bold)
          dataCell(
            "${sale['SALELITER']}",
            80,
            showRightBorder: true,
            alignment: Alignment.centerRight,
            isBold: true,
          ),

          // Amount Column (ညာဘက်ကပ် + Bold)
          dataCell(
            formatter.format(sale['TotalPrice']),
            120,
            showRightBorder: true,
            alignment: Alignment.centerRight,
            isBold: true,
          ),

          dataCell(
            "${sale['Sale_Type_name']}",
            150,
            cardColor: getSaleTypeColor(sale['Sale_Type_name'] ?? ''),
            showRightBorder: true,
            alignment: Alignment.center, // Sale Type Badge ကိုတော့ အလယ်မှာပဲထားမယ်
          ),

          // Status Column
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child:
                  sale['Sale_Type_name'] == 'Cash Sale' ||
                      sale['Sale_Type_name'] == 'ePayment' ||
                      sale['Sale_Type_name'] == 'Credit Sale'
                  ? CheckAlreadyCollected(sale: sale)
                  : IconButton(
                      style: ButtonStyle(),
                      onPressed: null,
                      icon: const Icon(Icons.not_interested_rounded, size: 20, color: Colors.red),
                      tooltip: '${sale['Sale_Type_name']} အတွက် ခွင့်မပြုပါ',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

//Check Already Collected Point
class CheckAlreadyCollected extends StatefulWidget {
  final Map<String, dynamic> sale;
  const CheckAlreadyCollected({super.key, required this.sale});

  @override
  State<CheckAlreadyCollected> createState() => _CheckAlreadyCollectedState();
}

//Check Already Collected Point
class _CheckAlreadyCollectedState extends State<CheckAlreadyCollected> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    // stationId နဲ့ VocNo ကို တွဲပြီး fullVocNo လုပ်မယ်
    final String fullVocNo = "${AppConfig.stationId}${widget.sale['VocNo']}";

    return Center(
      child: StreamBuilder<bool>(
        stream: checkIfExistsStream(fullVocNo),
        builder: (context, snapshot) {
          // ၁။ Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          // ၂။ Data Exists (Collect ပြီးသား)
          if (snapshot.data == true) {
            return const Icon(Icons.check_circle, color: Colors.green, size: 24);
          }

          // ၃။ Not Collected Yet (Button/Dialog ပြမယ်)
          // ဒီမှာ မူလ QR icon ပုံစံလေး ပြထားရင် ပုံ (image_5fc740.png) ထဲကအတိုင်း ပိုလှမယ်
          return TextFieldDialog(
            supabase: supabase,
            voc_no: widget.sale['VocNo'],
            vehical_no: widget.sale['Vehical_No'] ?? '',
            fuel_type: widget.sale['FuelTypeName'] ?? '',
            amount: widget.sale['TotalPrice']?.toString() ?? '0',
            sale_type: widget.sale['Sale_Type_name'] ?? '',
          );
        },
      ),
    );
  }
}

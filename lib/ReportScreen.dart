import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/BuildProgessOverlay.dart';
import 'package:station_msloyalty/Helper/DataCell.dart';
import 'package:station_msloyalty/Helper/FetchWithProgress.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/PumpBySaleReport.dart';
import 'package:station_msloyalty/Helper/SaleDetailReport.dart';
import 'package:station_msloyalty/Model/BuildFuelTypeChip.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
import 'package:station_msloyalty/Model/SaleTypeModel.dart';
import 'package:station_msloyalty/summary_view.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Screens/CheckAlreadyCollectedReport.dart';
import 'package:station_msloyalty/Screens/ReportDetailListScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreen();
}

class _ReportsScreen extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;
  final String apiUrl = "${AppConfig.apiUrl}/api/sales/recent";
  double _dragStartY = 0;
  final Set<int> _selectedIndices = {}; // Selected Indexes
  int? _lastSelectedIndex; // Last Selected Index

  List<dynamic> _salesData = [];

  DateTimeRange? _selectedDateRange; // Date Range
  // Map<String, dynamic>? _sysControl;
  List<dynamic> _sysControlList = []; // List to hold API response
  bool isLoadingSidebar = false; // Sidebar loading state

  //Range Text Controller for Time Closed
  final TextEditingController _rangeTimeClosedController =
      TextEditingController();

  // Start နှင့် End Time အတွက် Controller များ
  final TextEditingController _startDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final TextEditingController _endDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final TextEditingController _startTimeController = TextEditingController(
    text: "00:00:00",
  );
  final TextEditingController _endTimeController = TextEditingController(
    text: "23:59:59",
  );
  final StreamController<SalesLoadStatus> salesStreamController =
      StreamController<SalesLoadStatus>.broadcast();

  DateTime _combineDateAndTime(DateTime date, String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int s = int.parse(parts[2]);
      return DateTime(date.year, date.month, date.day, h, m, s);
    } catch (e) {
      // Error တက်ရင် default အချိန်ပေးခြင်း
      return date;
    }
  }

  @override
  void initState() {
    super.initState();
    // ၁။ ယနေ့ရဲ့ အစ (00:00:00) နှင့် အဆုံး (23:59:59) ကို သတ်မှတ်ခြင်း
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _selectedDateRange = DateTimeRange(start: todayStart, end: todayEnd);

    // ၂။ Selected Range ကို Initialize လုပ်ခြင်း
    _selectedDateRange = DateTimeRange(start: todayStart, end: todayEnd);
    // ၃။ App စဖွင့်ချင်း Data ခေါ်ယူခြင်း
    // ဤနေရာတွင် API နှစ်ခုလုံးကို တစ်ခါတည်း ခေါ်ပါမည်
    _fetchInitialData(todayStart, todayEnd);
  }

  // Initial Data Fetching
  Future<void> _fetchInitialData(DateTime start, DateTime end) async {
    // Sales Data နှင့် SysControl Data နှစ်ခုလုံးကို ခေါ်ယူခြင်း
    await Future.wait([
      _searchSalesByDate(start, end), // ယနေ့ Sale များ
      _fetchSysControlByRange(start, end), // ယနေ့ System Logs များ
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Select Handling SystemControl Time Closed Range
  void _handleTap(int index) {
    final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    setState(() {
      if (isShiftPressed) {
        // ၁။ Shift ဖိထားလျှင်: Range အလိုက် Select လုပ်မည် (ယခင်အတိုင်း)
        if (_lastSelectedIndex != null) {
          int start = _lastSelectedIndex! < index ? _lastSelectedIndex! : index;
          int end = _lastSelectedIndex! > index ? _lastSelectedIndex! : index;

          // Shift နဲ့ ထပ်တိုးချင်တာဆိုရင် Clear မလုပ်ဘူး၊
          // ဒါပေမဲ့ Range အသစ်ပဲ လိုချင်ရင်တော့ ဒီမှာ clear() တစ်ချက်လုပ်နိုင်တယ်
          _selectedIndices.clear();
          for (int i = start; i <= end; i++) {
            _selectedIndices.add(i);
          }
        } else {
          _selectedIndices.add(index);
        }
      } else {
        // ၂။ Shift မဖိထားလျှင်: အရင် Select လုပ်သမျှ အကုန်ဖြုတ်ပြီး ယခုတစ်ခုတည်းကိုပဲ ရွေးမည်
        _selectedIndices.clear();
        _selectedIndices.add(index);
        _lastSelectedIndex = index; // Range စမှတ်အဖြစ် မှတ်ထားမယ်
      }

      // အပေါ်က Date Range Field ကို Update လုပ်မယ်
      _updateUpperRangeField();
    });
  }

  // Update the upper range field based on selected indices
  void _updateUpperRangeField() {
    if (_selectedIndices.isEmpty) return;

    // ၁။ ရွေးထားတဲ့ Index တွေကို စီမယ်
    List<int> sortedIndices = _selectedIndices.toList()..sort();

    // ၂။ Start Date အတွက် ပထမဆုံးရွေးတဲ့ Item အချိန်ကို ယူမယ်
    DateTime startDT = DateTime.parse(
      _sysControlList[sortedIndices.first]['Sdate'],
    );

    DateTime endDT;

    // ၃။ Logic စစ်မယ်: တစ်ခုတည်းလား၊ အများကြီးလား?
    if (_selectedIndices.length == 1) {
      // တစ်ခုတည်းဆိုရင် End Date ကို ဒီနေ့ည ၂၃:၅၉:၅၉ သတ်မှတ်မယ်
      DateTime now = DateTime.now();
      endDT = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      // အများကြီးဆိုရင် နောက်ဆုံး Item ရဲ့ အချိန်ကို ယူမယ်
      endDT = DateTime.parse(_sysControlList[sortedIndices.last]['Sdate']);
    }

    // ၄။ Controller များထဲသို့ Set လုပ်ခြင်း
    setState(() {
      // Start Field များ (ရွေးထားတဲ့ Item ရဲ့ အချိန်)
      _startDateController.text = DateFormat('dd/MM/yyyy').format(startDT);
      _startTimeController.text = DateFormat('HH:mm:ss').format(startDT);

      // End Field များ (Today 23:59:59 သို့မဟုတ် Last Item အချိန်)
      _endDateController.text = DateFormat('dd/MM/yyyy').format(endDT);
      _endTimeController.text = DateFormat('HH:mm:ss').format(endDT);

      _selectedDateRange = DateTimeRange(start: startDT, end: endDT);
    });
  }

  //Search Sale By Date
  Future<void> _searchSalesByDate(DateTime start, DateTime end) async {
    // API အတွက် Format ပြောင်းခြင်း
    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    // Node.js API Route (Search endpoint ကို သုံးထားပါသည်)
    final url =
        '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr';

    // စတင်ချိန်မှာ Loading True နဲ့ 0% ပို့လိုက်မယ်
    salesStreamController.add(
      SalesLoadStatus(data: [], progress: 0.0, isLoading: true),
    );

    try {
      await fetchWithProgress(url, _salesData, salesStreamController);
    } catch (e) {
      debugPrint("Sales Fetch Error: $e");
    }
  }

  // Sidebar (System Control Logs) အတွက် Data Fetching
  Future<void> _fetchSysControlByRange(DateTime start, DateTime end) async {
    // Loading စတင်ဖွင့်ခြင်း
    setState(() => isLoadingSidebar = true);

    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    final url = Uri.parse(
      '${AppConfig.apiUrl}/api/system-control/search?start=$startStr&end=$endStr',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _sysControlList = data;
        });
      }
    } catch (e) {
      debugPrint("Sidebar Error: $e");
    } finally {
      // API ကော Error ကော ပြီးဆုံးသွားချိန်တွင် Loading ပြန်ပိတ်ခြင်း
      if (mounted) {
        setState(() => isLoadingSidebar = false);
      }
    }
  }

  // Sales Data ကို Sale Type အလိုက် ခွဲခြားတွက်ချက်ခြင်း
  Map<String, double> _calculateSalesByType() {
    Map<String, double> typeTotals = {};

    for (var sale in _salesData) {
      String typeName = sale['Sale_Type_name'] ?? 'Other';
      double amount = double.tryParse(sale['TotalPrice'].toString()) ?? 0.0;

      if (typeTotals.containsKey(typeName)) {
        typeTotals[typeName] = typeTotals[typeName]! + amount;
      } else {
        typeTotals[typeName] = amount;
      }
    }
    return typeTotals;
  }

  // Sales Summary ကိုတွက်ချက်ခြင်း
  Map<String, Map<String, double>> _calculateSalesSummary() {
    Map<String, Map<String, double>> summary = {};

    for (var sale in _salesData) {
      String typeName = sale['Sale_Type_name'] ?? 'Other';
      double amount = double.tryParse(sale['TotalPrice'].toString()) ?? 0.0;
      double liters = double.tryParse(sale['SALELITER'].toString()) ?? 0.0;

      if (summary.containsKey(typeName)) {
        summary[typeName]!['amount'] = summary[typeName]!['amount']! + amount;
        summary[typeName]!['liters'] = summary[typeName]!['liters']! + liters;
      } else {
        summary[typeName] = {'amount': amount, 'liters': liters};
      }
    }
    return summary;
  }

  Map<String, Map<String, double>> _calculateFuelSummary() {
    final Map<String, Map<String, double>> fuelSummary = {};

    // အရောင်းစာရင်း list ကို loop ပတ်၍ တွက်ချက်ခြင်း
    // (မှတ်ချက် - _salesList သည် သင်၏ data list အမည်ဖြစ်ရပါမည်)
    for (var sale in _salesData) {
      final type = sale['FuelTypeName'] ?? 'Unknown';
      final liter = (sale['SALELITER'] ?? 0).toDouble();
      final amount = (sale['TotalPrice'] ?? 0).toDouble();

      if (fuelSummary.containsKey(type)) {
        fuelSummary[type]!['liters'] = fuelSummary[type]!['liters']! + liter;
        fuelSummary[type]!['amount'] = fuelSummary[type]!['amount']! + amount;
      } else {
        fuelSummary[type] = {'liters': liter, 'amount': amount};
      }
    }
    return fuelSummary;
  }

  // နောက်ဆုံး Sale ၂၀ ကို API မှ ဆွဲယူခြင်း
  Future<void> _fetchLatestSales() async {
    // စတင်ချိန်မှာ Loading True နဲ့ 0% ပို့လိုက်မယ်
    salesStreamController.add(
      SalesLoadStatus(data: [], progress: 0.0, isLoading: true),
    );
    try {
      await fetchWithProgress(apiUrl, _salesData, salesStreamController);
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MsAppBar(
        title: 'Sale Details Report',
        showBackButton: true,
      ),

      endDrawer: _buildRightSidebar(),
      body: StreamBuilder<SalesLoadStatus>(
        stream: salesStreamController.stream,
        builder: (context, snapshot) {
          // လက်ရှိ status ကို ယူမယ် (မရှိသေးရင် default status ပေးထားမယ်)
          final status =
              snapshot.data ??
              SalesLoadStatus(data: [], progress: 0.0, isLoading: true);

          final isMobile = MediaQuery.of(context).size.width < 1000;
          
          return Stack(
            children: [
              isMobile
                  ? ListView(
                      children: [
                        _buildDateSearchRow(isMobile, status.data),
                        SummaryView(
                          saleSummaryTable: _buildTypeSummaryTable(isMobile),
                          fuelSummaryTable: _buildFuelSummaryTable(isMobile),
                        ),
                        _buildHeaderInfo(isMobile),
                        _salesData.isEmpty
                            ? _buildEmptyState()
                            : _buildMobileShowDetailButton(status.data),
                      ],
                    )
                  : Column(
                      children: [
                        _buildDateSearchRow(isMobile, status.data),
                        SummaryView(
                          saleSummaryTable: _buildTypeSummaryTable(isMobile),
                          fuelSummaryTable: _buildFuelSummaryTable(isMobile),
                        ),
                        _buildHeaderInfo(isMobile),
                        Expanded(
                          flex: 1,
                          child: _salesData.isEmpty
                              ? _buildEmptyState()
                              : _buildDataTable(status.data, status.isLoading),
                        ),
                      ],
                    ),
              Visibility(
                visible: status.isLoading,
                child: buildProgressOverlay(
                  status.progress,
                  status.data.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build Header Information
  Widget _buildHeaderInfo(bool isMobile) {
    double grandTotalLiter = _salesData.fold(
      0,
      (prev, element) =>
          prev + (double.tryParse(element['SALELITER'].toString()) ?? 0),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: (isDark ? StyleConstants.darkBg : Colors.blueGrey.shade50)
            .withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 20,
        runSpacing: 20,
        children: [
          _buildSummaryChip(
            "စုစုပေါင်းငွေ",
            "${NumberFormat('#,###').format(_salesData.fold<num>(0, (num sum, item) => sum + (item['TotalPrice'] ?? 0)))} Ks",
            Colors.green,
            isDark,
          ),
          _buildSummaryChip(
            "စုစုပေါင်းလီတာ",
            "${grandTotalLiter.toStringAsFixed(2)} Lit",
            Colors.blue,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.blueGrey,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: color,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Build Data Table
  Widget _buildDataTable(List<dynamic> data, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? StyleConstants.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        // ၁။ Fixed Header အပိုင်း (ဒီကောင်က Scroll မဖြစ်ပါ)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 1200,
            decoration: BoxDecoration(
              color: headerColor,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.teal).withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Row(
              children: [
                _buildHeaderCell('No', 1, textColor),
                _buildHeaderCell('Voucher No', 2, textColor),
                _buildHeaderCell('Fuel Type', 2, textColor),
                _buildHeaderCell('Price', 2, textColor),
                _buildHeaderCell('Date & Time', 3, textColor),
                _buildHeaderCell('Vehicle No', 2, textColor),
                _buildHeaderCell('Sale Type', 2, textColor),
                _buildHeaderCell('Liter', 2, textColor),
                _buildHeaderCell('Amount', 2, textColor),
                _buildHeaderCell('Action', 2, textColor),
              ],
            ),
          ),
        ),

        // ၂။ Scrollable Body အပိုင်း
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty && !isLoading
              ? const Center(child: Text("မှတ်တမ်းမရှိပါ"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200, // Fixed width for horizontal scrolling
                    child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final sale = data[index];
                          final bool isEven = index % 2 == 0;
                          final Color rowColor = isEven
                              ? (isDark
                                    ? StyleConstants.darkBg
                                    : Colors.blueGrey.shade50)
                              : (isDark ? StyleConstants.darkSurface : Colors.white);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              color: rowColor,
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      (isDark ? Colors.white : Colors.grey.shade300)
                                          .withOpacity(0.1),
                                ),
                                left: BorderSide(
                                  color: Colors.grey.shade300,
                                ), // ဘယ်ဘက်မျဉ်း
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                ), // ညာဘက်မျဉ်း
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildTableCell(
                                  '${index + 1}',
                                  1,
                                  isText: true,
                                ), // အမှတ်စဉ်
                                _buildTableCell(
                                  '${sale['VocNo']}',
                                  2,
                                  isText: true,
                                ), // Invoice No
                                dataCell(
                                  "${sale['FuelTypeName']}",
                                  150,
                                  cardColor: getFuelColor(sale['FuelTypeName'] ?? ''),
                                  showRightBorder: true,
                                  alignment: Alignment
                                      .center, // Sale Type Badge ကိုတော့ အလယ်မှာပဲထားမယ်
                                ),
                                // ယနေ့ပေါက်ဈေး (D1_FuelType မှလာသော SalePrice)
                                _buildTableCell(
                                  NumberFormat(
                                    '#,###',
                                  ).format(sale['TodayPrice'] ?? 0),
                                  2,
                                  isNumeric: true,
                                ),
                                _buildTableCell(
                                  DateFormat(
                                    'dd-MM-yy HH:mm:ss',
                                  ).format(DateTime.parse(sale['S_Date'])),
                                  3,
                                ),
                                _buildTableCell(
                                  '${sale['Vehical_No'] ?? '-'}',
                                  2,
                                  isText: true,
                                ), // Vehicle No
                                // _buildTableCell('${sale['Sale_Type_name'] ?? '-'}', 2),
                                dataCell(
                                  "${sale['Sale_Type_name']}",
                                  150,
                                  cardColor: getSaleTypeColor(
                                    sale['Sale_Type_name'] ?? '',
                                  ),
                                  showRightBorder: true,
                                  alignment: Alignment
                                      .center, // Sale Type Badge ကိုတော့ အလယ်မှာပဲထားမယ်
                                ),
      
                                _buildTableCell(
                                  '${double.tryParse(sale['SALELITER'].toString())?.toStringAsFixed(2)}',
                                  2,
                                ),
                                _buildTableCell(
                                  NumberFormat('#,###').format(
                                    double.tryParse(sale['TotalPrice'].toString()) ??
                                        0,
                                  ),
                                  2,
                                  isNumeric: true,
                                ),
                                sale['Sale_Type_name'] == 'Cash Sale' ||
                                        sale['Sale_Type_name'] == 'ePayment'
                                    ? _buildTableCell(
                                        CheckAlreadyCollectedReport(sale: sale, supabase: supabase),
                                        2,
                                        isAction: true,
                                      )
                                    : _buildTableCell(
                                        IconButton(
                                          onPressed: null,
                                          icon: const Icon(
                                            Icons.not_interested_rounded,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          tooltip:
                                              '${sale['Sale_Type_name']} အတွက် ခွင့်မပြုပါ',
                                        ),
                                        2,
                                        isAction: true,
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                ),
        ),
      ],
    );
  }

  // Build Table Cell
  Widget _buildTableCell(
    dynamic content,
    int flexValue, {
    bool isNumeric = false,
    bool isText = false,
    bool isBold = false,
    bool isAction = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final align = isNumeric
        ? TextAlign.right
        : (isText ? TextAlign.left : TextAlign.center);
    return Expanded(
      flex: flexValue,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 1,
        ), // Cell Padding
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: (isDark ? Colors.white : Colors.grey.shade300).withOpacity(
                0.1,
              ),
            ), // ကော်လံကြားမျဉ်း (Vertical Line)
          ),
        ),
        child: isAction && content is Widget
            ? content
            : Text(
                content?.toString() ?? '',
                textAlign: align,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? Colors.white : StyleConstants.lightText,
                ),
              ),
      ),
    );
  }

  // Sale Type Summary Table
  Widget _buildTypeSummaryTable(bool isMobile) {
    final summaryData = _calculateSalesSummary();

    // Amount အလိုက် Sort လုပ်ခြင်း
    final sortedEntries = summaryData.entries.toList()
      ..sort((a, b) => b.value['amount']!.compareTo(a.value['amount']!));

    return Container(
      width: isMobile 
          ? double.infinity 
          : MediaQuery.of(context).size.width * 0.5 - 20,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.teal.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Sale Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Liter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows: sortedEntries.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Liter ကို ဒသမ ၂ လုံးဖြင့်ပြသခြင်း
                        DataCell(
                          Text(
                            entry.value['liters']!.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        // Amount ကို ပုဒ်ဖြတ်ကော်မာဖြင့်ပြသခြင်း
                        DataCell(
                          Text(
                            NumberFormat('#,###').format(entry.value['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fuel Summary Table
  Widget _buildFuelSummaryTable(bool isMobile) {
    final fuelData = _calculateFuelSummary();

    // Amount အလိုက် အများဆုံးမှ အနည်းဆုံးသို့ Sort လုပ်ခြင်း
    final sortedFuelEntries = fuelData.entries.toList()
      ..sort((a, b) => b.value['amount']!.compareTo(a.value['amount']!));

    return Container(
      width: isMobile 
          ? double.infinity 
          : MediaQuery.of(context).size.width * 0.5 - 20,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 10,
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.orange.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Fuel Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Liter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows: sortedFuelEntries.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Liter ကို ဒသမ ၂ လုံးဖြင့်ပြသခြင်း
                        DataCell(
                          Text(
                            entry.value['liters']!.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            NumberFormat('#,###').format(entry.value['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileShowDetailButton(List<dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded, size: 64, color: Colors.teal.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "${data.length} Records Found",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap below to see full details with search & filters",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailListScreen(
                        salesData: data,
                        supabase: supabase,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text("SHOW FULL DETAILS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text("ဒေတာများ ဆွဲယူ၍မရပါ (သို့မဟုတ်) မရှိပါ"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchLatestSales,
            child: const Text("ပြန်လုပ်ကြည့်ရန်"),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String? typeName) {
    switch (typeName?.toUpperCase()) {
      case 'Cash Sale':
        return Colors.green;
      case 'Credit Sale':
        return Colors.orange;
      case 'FOC':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // Sidebar Widget
  Widget _buildRightSidebar() {
    return Drawer(
      width: 250,

      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey.shade900),
            child: InkWell(
              // Header ကို နှိပ်ရင်လည်း Date ရွေးလို့ရအောင် လုပ်ထားတယ်
              onTap: () => _pickDateRange(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "System Control Logs",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  // လက်ရှိရွေးထားတဲ့ Range ကို ပြပေးမယ်
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.date_range, color: Colors.white),
                        Text(
                          "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _sysControlList.isEmpty
                ? const Center(child: Text("No records found in this range."))
                : // UI ထဲက ListView
                  GestureDetector(
                    onVerticalDragStart: (details) {
                      // Mouse စဖိတဲ့နေရာက Y position ကို မှတ်မယ်
                      _dragStartY = details.localPosition.dy;

                      // Shift မဖိထားရင် အဟောင်းတွေကို ရှင်းပစ်ချင်ရင် ဒီမှာရှင်းနိုင်ပါတယ်
                      if (!HardwareKeyboard.instance.isShiftPressed) {
                        setState(() => _selectedIndices.clear());
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      double currentY = details.localPosition.dy;
                      double itemHeight =
                          70.0; // သားကြီးရဲ့ ListTile အမြင့် (Card margin ပါတွက်ပါ)

                      // လက်ရှိ Mouse ရောက်နေတဲ့နေရာရဲ့ Index ကို တွက်မယ်
                      int startIndex = (_dragStartY / itemHeight).floor();
                      int currentIndex = (currentY / itemHeight).floor();

                      setState(() {
                        int start = startIndex < currentIndex
                            ? startIndex
                            : currentIndex;
                        int end = startIndex > currentIndex
                            ? startIndex
                            : currentIndex;

                        // Range ထဲက index တွေကို select လုပ်မယ်
                        for (int i = start; i <= end; i++) {
                          if (i >= 0 && i < _sysControlList.length) {
                            _selectedIndices.add(i);
                          }
                        }
                        _updateUpperRangeField(); // အပေါ်က Field ကိုပါ auto update လုပ်မယ်
                      });
                    },
                    child: ListView.builder(
                      itemCount: _sysControlList.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedIndices.contains(index);

                        return InkWell(
                          onTap: () => _handleTap(index),
                          child: Container(
                            color: isSelected
                                ? Colors.blue
                                : Colors
                                      .transparent, // Select ဖြစ်ရင် အရောင်ပြောင်းမယ်
                            child: ListTile(
                              title: Text(
                                "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_sysControlList[index]['Sdate'].toString()))}",
                                style: isSelected
                                    ? const TextStyle(color: Colors.white)
                                    : const TextStyle(color: Colors.black),
                              ),
                              subtitle: Text(
                                "Time: ${DateFormat('HH:mm:ss').format(DateTime.parse(_sysControlList[index]['Sdate'].toString()))}",
                                style: isSelected
                                    ? const TextStyle(color: Colors.white)
                                    : const TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          Row(
            children: [
              // Start Date & Time
              Expanded(
                child: TextField(
                  controller: _startDateController,
                  decoration: InputDecoration(labelText: "Start Date"),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _startTimeController,
                  decoration: InputDecoration(labelText: "Start Time"),
                ),
              ),

              const Icon(Icons.arrow_forward), // မြားလေးနဲ့ ပြရင် ပိုမိုက်တယ်
              // End Date & Time
              Expanded(
                child: TextField(
                  controller: _endDateController,
                  decoration: InputDecoration(labelText: "End Date"),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _endTimeController,
                  decoration: InputDecoration(labelText: "End Time"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pick Date Range
  Future<void> _pickDateRange(BuildContext context) async {
    DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.blueGrey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
      // Data ကို ချက်ချင်း ပြန်ခေါ်မယ်
      _fetchSysControlByRange(newRange.start, newRange.end);
    }
  }

  // Date Search Row
  Widget _buildDateSearchRow(bool isMobile, List<dynamic> data) {
    if (isMobile) {
      return _buildMobileSelectionView(data);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? Colors.blueGrey.shade900 : Colors.blueGrey.shade50,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildMobileDatePickers(isMobile),
          _buildSearchButtons(isMobile),
          _buildReportButtons(isMobile),
          _buildRecordSummary(data, isMobile),
        ],
      ),
    );
  }

  Widget _buildMobileSelectionView(List<dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? StyleConstants.darkBg : Colors.white,
      ),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDateTimeSegment(
                  title: "START",
                  dateController: _startDateController,
                  timeController: _startTimeController,
                  icon: Icons.play_circle_outline,
                  color: Colors.green,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                _buildDateTimeSegment(
                  title: "END",
                  dateController: _endDateController,
                  timeController: _endTimeController,
                  icon: Icons.stop_circle_outlined,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final start = _combineDateAndTime(_selectedDateRange!.start, _startTimeController.text);
                    final end = _combineDateAndTime(_selectedDateRange!.end, _endTimeController.text);
                    await _searchSalesByDate(start, end);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text("SEARCH NOW"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _fetchLatestSales,
                  icon: const Icon(Icons.history, color: Colors.teal),
                  tooltip: "Latest 20",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportDetail(),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text("DETAIL"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportSummary(),
                  icon: const Icon(Icons.summarize_outlined, size: 18),
                  label: const Text("SUMMARY"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSegment({
    required String title,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _pickDateForController(dateController, title == "START"),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("DATE", style: TextStyle(fontSize: 9, color: Colors.grey)),
                          Text(dateController.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 25, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TIME", style: TextStyle(fontSize: 9, color: Colors.grey)),
                        SizedBox(
                          height: 25,
                          child: TextField(
                            controller: timeController,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateForController(TextEditingController controller, bool isStart) async {
    DateTime initial = isStart ? _selectedDateRange!.start : _selectedDateRange!.end;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedDateRange = DateTimeRange(start: picked, end: _selectedDateRange!.end);
        } else {
          _selectedDateRange = DateTimeRange(start: _selectedDateRange!.start, end: picked);
        }
        controller.text = DateFormat("dd-MM-yyyy").format(picked);
      });
    }
  }

  Widget _buildMobileDatePickers(bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _dateTextField(_startDateController, "From Date"),
            _timeTextField(_startTimeController, "Start Time"),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(" TO ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _dateTextField(_endDateController, "To Date"),
            _timeTextField(_endTimeController, "End Time"),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchButtons(bool isMobile) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            final start = _combineDateAndTime(_selectedDateRange!.start, _startTimeController.text);
            final end = _combineDateAndTime(_selectedDateRange!.end, _endTimeController.text);
            await _searchSalesByDate(start, end);
          },
          icon: const Icon(Icons.search),
          label: const Text("Search"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            minimumSize: const Size(160, 45),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _fetchLatestSales,
          icon: const Icon(Icons.receipt_long_rounded),
          label: const Text("Last 20 Sales"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(160, 45),
          ),
        ),
      ],
    );
  }

  Widget _buildReportButtons(bool isMobile) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _exportDetail(),
          icon: const Icon(Icons.description),
          label: const Text("Detail Report"),
          style: ElevatedButton.styleFrom(minimumSize: const Size(180, 45)),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _exportSummary(),
          icon: const Icon(Icons.summarize),
          label: const Text("Summary Report"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(180, 45),
          ),
        ),
      ],
    );
  }

  Future<void> _exportDetail() async {
    salesStreamController.add(SalesLoadStatus(data: _salesData, progress: 0.0, isLoading: true));
    try {
      await exportSaleDetailReport(List<Map<String, dynamic>>.from(_salesData));
    } finally {
      salesStreamController.add(SalesLoadStatus(data: _salesData, progress: 1.0, isLoading: false));
    }
  }

  void _exportSummary() {
    exportSaleDataReport(
      _salesData.toList(),
      AppConfig.stationName,
      "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} ${_startTimeController.text}",
      "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)} ${_endTimeController.text}",
    );
  }

  Widget _buildRecordSummary(List<dynamic> data, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _infoRow("From", "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} ${_startTimeController.text}"),
        _infoRow("To", "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)} ${_endTimeController.text}"),
        _infoRow("Record", "${data.length}"),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(":  $value"),
        ],
      ),
    );
  }


  // Date Text Field
  Widget _dateTextField(TextEditingController controller, String label) {
    return Row(
      children: [
        // --- From Date Section ---
        IconButton(
          onPressed: () async {
            DateTime? d = await showDatePicker(
              context: context,
              initialDate: _selectedDateRange!.start,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) {
              setState(() {
                _selectedDateRange = DateTimeRange(
                  start: d,
                  end: _selectedDateRange!.end,
                );
                controller.text = DateFormat("dd-MM-yyyy").format(d);
              });
            }
          },
          icon: const Icon(Icons.calendar_month),
          tooltip: "From Date",
        ),
        const SizedBox(width: 8),
        Container(
          width: 110,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              hintText: "dd-mm-yyyy",
              border: const OutlineInputBorder(),
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // ၁။ ဂဏန်းမဟုတ်တာ အကုန်ဖယ်ပါ
              String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

              // ၂။ Default အပိုင်းများ သတ်မှတ်ခြင်း (dd, mm, yyyy)
              String dd = "01";
              String mm = "01";
              String yyyy = "2026";

              // ၃။ ရိုက်လိုက်သည့် ဂဏန်းများကို အစဉ်လိုက် ခွဲထုတ်ခြင်း
              if (digits.length >= 2) {
                dd = digits.substring(0, 2);
              } else if (digits.isNotEmpty) {
                dd = digits.padLeft(2, '0');
              }

              if (digits.length >= 4) {
                mm = digits.substring(2, 4);
              } else if (digits.length > 2) {
                mm = digits.substring(2).padLeft(2, '0');
              }

              if (digits.length >= 8) {
                yyyy = digits.substring(4, 8);
              } else if (digits.length > 4) {
                yyyy = digits.substring(4).padLeft(4, '0');
              }

              // ၄။ Validation (ရက် ၃၁၊ လ ၁၂ ထက်မကျော်စေရန်)
              if (int.parse(dd) > 31) dd = "31";
              if (int.parse(dd) == 0) dd = "01";
              if (int.parse(mm) > 12) mm = "12";
              if (int.parse(mm) == 0) mm = "01";

              String formatted = "$dd-$mm-$yyyy";

              // ၅။ Controller ကို Update လုပ်ခြင်း
              if (value != formatted) {
                int currentOffset = controller.selection.baseOffset;
                controller.value = TextEditingValue(
                  text: formatted,
                  // Cursor ကို လက်ရှိနေရာမှာပဲ ဆက်ရှိနေစေရန်
                  selection: TextSelection.collapsed(
                    offset: currentOffset <= formatted.length
                        ? currentOffset
                        : formatted.length,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Time Text Field
  Widget _timeTextField(TextEditingController controller, String label) {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.blueGrey),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              hintText: "00:00:00",
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // ၁။ ဂဏန်းမဟုတ်တာ အကုန်ဖယ်ပါ
              String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

              // ၂။ အကယ်၍ User က အကုန်ဖျက်လိုက်ရင် default ပြန်ပေးပါ (optional)
              if (digits.isEmpty) return;

              // ၃။ အမြဲတမ်း ဂဏန်း ၆ လုံး (hhmmss) ရှိနေအောင် ပုံသေထားပါမည်
              // ဤနည်းလမ်းသည် Select လုပ်ပြီး ရိုက်လျှင်လည်း Format မပျက်စေပါ
              String hh = "00";
              String mm = "00";
              String ss = "00";

              if (digits.length >= 2) {
                hh = digits.substring(0, 2);
              } else {
                hh = digits.padLeft(2, '0');
              }

              if (digits.length >= 4) {
                mm = digits.substring(2, 4);
              } else if (digits.length > 2)
                mm = digits.substring(2).padLeft(2, '0');

              if (digits.length >= 6) {
                ss = digits.substring(4, 6);
              } else if (digits.length > 4)
                ss = digits.substring(4).padLeft(2, '0');

              // ၄။ Validation (နာရီ ၂၄၊ မိနစ် ၆၀ ထက်မကျော်စေရန်)
              if (int.parse(hh) > 23) hh = "23";
              if (int.parse(mm) > 59) mm = "59";
              if (int.parse(ss) > 59) ss = "59";

              String formatted = "$hh:$mm:$ss";

              // ၅။ Controller ကို Update လုပ်ခြင်း
              if (value != formatted) {
                int currentOffset = controller.selection.baseOffset;
                controller.value = TextEditingValue(
                  text: formatted,
                  // Cursor position ကို မပျောက်အောင် ထိန်းပေးခြင်း
                  selection: TextSelection.collapsed(
                    offset: currentOffset <= formatted.length
                        ? currentOffset
                        : formatted.length,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Helper: "dd-mm-yyyy" -> "yyyy-mm-dd"
  String convertToSqlDate(String dateStr) {
    List<String> p = dateStr.split('-');
    return "${p[2]}-${p[1]}-${p[0]}"; // Year-Month-Day
  }
}


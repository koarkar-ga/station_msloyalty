import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/PumpBySaleReport.dart';
import 'package:station_msloyalty/Helper/TextFieldDialog.dart';
import 'package:station_msloyalty/Model/SaleDataModel.dart';
import 'package:station_msloyalty/config.dart';
import 'package:station_msloyalty/main.dart';
import 'package:station_msloyalty/summary_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPage();
}

class _DashboardPage extends State<DashboardPage> {
  // API Configurations
  // Windows Desktop တွင် local run ထားသော Node.js အတွက် localhost:3000 သုံးနိုင်သည်
  final String apiUrl = "${AppConfig.apiUrl}/api/sales/recent";
  final String apiEhoSendCount = "${AppConfig.apiUrl}/api/eho/send-count";

  final supabase = Supabase.instance.client;

  List<dynamic> _salesData = [];
  bool _isLoadingSales = false;
  bool _isApiOnline = false;
  bool _isEhoUpdate = false;
  int _ehoRemainingToSendCount = 0;
  Timer? _statusTimer;
  DateTimeRange? _selectedDateRange; // ရက်စွဲ နှစ်ခုအတွက်
  // Map<String, dynamic>? _sysControl;
  List<dynamic> _sysControlList = []; // API မှလာမည့် list ကို သိမ်းရန်
  bool isLoadingSidebar = false; // Sidebar loading state အတွက်
  // Start နှင့် End Time အတွက် Controller များ
  final TextEditingController _startDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final TextEditingController _endDateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final TextEditingController _startTimeController = TextEditingController(text: "00:00:00");
  final TextEditingController _endTimeController = TextEditingController(text: "23:59:59");

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

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

    // ၅ စက္ကန့်တစ်ခါ API Status ကို စစ်ဆေးရန်
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkConnection();
      await _ehoRemainingToSend();
      print("API Status: $_isApiOnline");
      print("EHO Remaining to send: $_ehoRemainingToSendCount");
    });
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
    _statusTimer?.cancel();
    super.dispose();
  }

  // API Connection အခြေအနေကို စစ်ဆေးခြင်း
  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        setState(() {
          _isApiOnline = response.statusCode == 200;
        });
      }
    } catch (e) {
      setState(() => _isApiOnline = false);
    }
  }

  // EHO Reaming to send count
  // API Connection အခြေအနေကို စစ်ဆေးခြင်း
  Future<void> _ehoRemainingToSend() async {
    try {
      final response = await http
          .get(Uri.parse(apiEhoSendCount))
          .timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _ehoRemainingToSendCount = data[0]['COUNT'];
          _ehoRemainingToSendCount < 100 ? _isEhoUpdate = true : _isEhoUpdate = false;
        });
      } else {
        setState(() {
          _ehoRemainingToSendCount = json.decode(response.body)[''];
          _ehoRemainingToSendCount < 100 ? _isEhoUpdate = true : _isEhoUpdate = false;
        });
      }
    } catch (e) {
      setState(() => _isEhoUpdate = false);
    }
  }

  Future<void> _searchSalesByDate(DateTime start, DateTime end) async {
    // Loading စတင်ဖွင့်ခြင်း
    setState(() => _isLoadingSales = true);

    // API အတွက် Format ပြောင်းခြင်း
    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    // Node.js API Route (Search endpoint ကို သုံးထားပါသည်)
    final url = Uri.parse(
      '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _salesData = data;
          _isApiOnline = true; // Connection status ကိုပါ update လုပ်ပေးခြင်း
        });
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Sales Fetch Error: $e");
      if (mounted) setState(() => _isApiOnline = false);
    } finally {
      // ပြီးဆုံးသွားချိန်တွင် Loading ပြန်ပိတ်ခြင်း
      if (mounted) {
        setState(() => _isLoadingSales = false);
      }
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
    setState(() => _isLoadingSales = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _salesData = json.decode(response.body);
          _isApiOnline = true;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isApiOnline = false);
    } finally {
      setState(() => _isLoadingSales = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/moonsun_logo.png', height: 30),
            const SizedBox(width: 10),
            const Text("Station MS Loyalty Dashboard"),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          const SizedBox(width: 20),
          _buildStatusIndicator(),
          IconButton(
            onPressed: _fetchLatestSales,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
          ),
          const SizedBox(width: 10),
          // Sidebar ကို ဖွင့်မည့် ခလုတ်
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_time),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 20),
          Text("ယနေ့ရက်စွဲ: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}"),
          const SizedBox(width: 20),
        ],
      ),

      endDrawer: _buildRightSidebar(),
      body: _isLoadingSales
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                //_buildSearchHeader(),
                _buildDateSearchRow(), // Date Range Picker Button
                //Summary Table ကို ခေါ်သုံးပါ ---
                SummaryView(
                  saleSummaryTable: _buildTypeSummaryTable(),
                  fuelSummaryTable: _buildFuelSummaryTable(),
                ),
                // Header Information
                _buildHeaderInfo(),
                Expanded(
                  flex: 1,
                  child: _salesData.isEmpty ? _buildEmptyState() : _buildDataTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusIndicator() {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          _isEhoUpdate
              ? "EHO ONLINE : $_ehoRemainingToSendCount"
              : "EHO OFFLINE : $_ehoRemainingToSendCount",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        const SizedBox(width: 20),
        Divider(),
        Icon(Icons.circle, size: 12, color: _isApiOnline ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          _isApiOnline ? "API ONLINE" : "API OFFLINE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isApiOnline ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    double grandTotalLiter = _salesData.fold(
      0,
      (prev, element) => prev + (double.tryParse(element['SALELITER'].toString()) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.blueGrey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "စုစုပေါင်းငွေ: ${NumberFormat('#,###').format(_salesData.fold<num>(0, (num sum, item) => sum + (item['TotalPrice'] ?? 0)))} Ks",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          // UI တွင်ပြသရန်:
          Text(
            "စုစုပေါင်းလီတာ: ${grandTotalLiter.toStringAsFixed(2)} Lit",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Column(
      children: [
        // ၁။ Fixed Header အပိုင်း (ဒီကောင်က Scroll မဖြစ်ပါ)
        Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            border: Border.all(color: Colors.teal), // ပတ်ပတ်လည် Border
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Padding
          child: const Row(
            children: [
              Expanded(
                flex: 0,
                child: Text(
                  'No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '  Voucher No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Fuel Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Today Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Date & Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Vehicle No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Sale Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Liter',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Action  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // ၂။ Scrollable Body အပိုင်း
        Expanded(
          child: _isLoadingSales
              ? const Center(child: CircularProgressIndicator())
              : _salesData.isEmpty
              ? const Center(child: Text("မှတ်တမ်းမရှိပါ"))
              : ListView.builder(
                  itemCount: _salesData.length,
                  itemBuilder: (context, index) {
                    final sale = _salesData[index];
                    // index ကို ၂ နဲ့စားလို့ ပြတ်ရင် အရောင်ဖျော့၊ မပြတ်ရင် အဖြူရောင်
                    final bool isEven = index % 2 == 0;
                    final Color rowColor = isEven ? Colors.blueGrey.shade50 : Colors.white;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                      decoration: BoxDecoration(
                        color: rowColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300), // အလျားလိုက်မျဉ်း
                          left: BorderSide(color: Colors.grey.shade300), // ဘယ်ဘက်မျဉ်း
                          right: BorderSide(color: Colors.grey.shade300), // ညာဘက်မျဉ်း
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTableCell('${index + 1}', 0, isText: true), // အမှတ်စဉ်
                          _buildTableCell('${sale['VocNo']}', 2, isText: true), // Invoice No
                          _buildTableCell(
                            '${sale['FuelTypeName'] ?? '-'}',
                            2,
                            isText: true,
                          ), // Fuel Type
                          // ယနေ့ပေါက်ဈေး (D1_FuelType မှလာသော SalePrice)
                          _buildTableCell(
                            NumberFormat('#,###').format(sale['TodayPrice'] ?? 0),
                            2,
                            isNumeric: true,
                          ),
                          _buildTableCell(
                            DateFormat('dd-MM-yy HH:mm:ss').format(DateTime.parse(sale['S_Date'])),
                            3,
                          ),
                          _buildTableCell(
                            '${sale['Vehical_No'] ?? '-'}',
                            2,
                            isText: true,
                          ), // Vehicle No
                          _buildTableCell('${sale['Sale_Type_name'] ?? '-'}', 2),
                          _buildTableCell(
                            '${double.tryParse(sale['SALELITER'].toString())?.toStringAsFixed(2)}',
                            2,
                          ),
                          _buildTableCell(
                            NumberFormat(
                              '#,###',
                            ).format(double.tryParse(sale['TotalPrice'].toString()) ?? 0),
                            2,
                            isNumeric: true,
                          ),
                          sale['Sale_Type_name'] == 'Cash Sale'
                              ? _buildTableCell(
                                  TextFieldDialog(
                                    supabase: supabase,
                                    voc_no: sale['VocNo'],
                                    vehical_no: sale['Vehical_No'],
                                    fuel_type: sale['FuelTypeName'] ?? '',
                                    amount: sale['TotalPrice']?.toString() ?? '0',
                                    sale_type: sale['Sale_Type_name'] ?? '',
                                  ),
                                  2,
                                  isAction: true,
                                )
                              : _buildTableCell(
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.not_interested_rounded,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    tooltip: '${sale['Sale_Type_name']} အတွက် ခွင့်မပြုပါ',
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
      ],
    );
  }

  Widget _buildTableCell(
    dynamic content,
    int flexValue, {
    bool isNumeric = false,
    bool isText = false,
    bool isBold = false,
    bool isAction = false,
  }) {
    final align = isNumeric ? TextAlign.right : (isText ? TextAlign.left : TextAlign.center);
    return Expanded(
      flex: flexValue,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1), // Cell Padding
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300), // ကော်လံကြားမျဉ်း (Vertical Line)
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
                ),
              ),
      ),
    );
  }

  Widget _buildTypeSummaryTable() {
    final summaryData = _calculateSalesSummary();

    // Amount အလိုက် Sort လုပ်ခြင်း
    final sortedEntries = summaryData.entries.toList()
      ..sort((a, b) => b.value['amount']!.compareTo(a.value['amount']!));

    return SizedBox(
      width:
          MediaQuery.of(context).size.width * 0.5 - 20, // Screen width ရဲ့ 50% နဲ့ margin ထည့်ခြင်း
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
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.teal.withOpacity(0.1)),
                  columns: const [
                    DataColumn(
                      label: Text('Sale Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Total Liter', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            ),
                          ),
                        ),
                        // Liter ကို ဒသမ ၂ လုံးဖြင့်ပြသခြင်း
                        DataCell(Text(entry.value['liters']!.toStringAsFixed(2))),
                        // Amount ကို ပုဒ်ဖြတ်ကော်မာဖြင့်ပြသခြင်း
                        DataCell(
                          Text(
                            NumberFormat('#,###').format(entry.value['amount']),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
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

  Widget _buildFuelSummaryTable() {
    final fuelData = _calculateFuelSummary();

    // Amount အလိုက် အများဆုံးမှ အနည်းဆုံးသို့ Sort လုပ်ခြင်း
    final sortedFuelEntries = fuelData.entries.toList()
      ..sort((a, b) => b.value['amount']!.compareTo(a.value['amount']!));

    return SizedBox(
      width:
          MediaQuery.of(context).size.width * 0.5 - 20, // Screen width ရဲ့ 50% နဲ့ margin ထည့်ခြင်း
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
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  horizontalMargin: 10,
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(Colors.orange.withOpacity(0.1)),
                  columns: const [
                    DataColumn(
                      label: Text('Fuel Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Total Liter', style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            ),
                          ),
                        ),
                        // Liter ကို ဒသမ ၂ လုံးဖြင့်ပြသခြင်း
                        DataCell(Text(entry.value['liters']!.toStringAsFixed(2))),
                        DataCell(
                          Text(
                            NumberFormat('#,###').format(entry.value['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text("ဒေတာများ ဆွဲယူ၍မရပါ (သို့မဟုတ်) မရှိပါ"),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchLatestSales, child: const Text("ပြန်လုပ်ကြည့်ရန်")),
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
      width: 350, // Sidebar အကျယ်ကို အနည်းငယ် တိုးထားပါသည်
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey.shade900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text(
                  "System Control Logs",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "${DateFormat('dd/MM HH:mm').format(_selectedDateRange!.start)} TO ${DateFormat('dd/MM HH:mm').format(_selectedDateRange!.end)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: _sysControlList.isEmpty
                ? const Center(child: Text("No records found in this range."))
                : ListView.builder(
                    itemCount: _sysControlList.length,
                    itemBuilder: (context, index) {
                      final item = _sysControlList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade100,
                            child: Text("${index + 1}", style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(
                            "HO: ${item['HO'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Option: ${item['soption'] ?? '-'}"),
                              Text(
                                "Date: ${item['Sdate'] != null ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(item['Sdate'])) : '-'}",
                                style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
          // Sidebar အောက်ခြေတွင် Refresh လုပ်ရန် ခလုတ်
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _fetchSysControlByRange(_selectedDateRange!.start, _selectedDateRange!.end),
              icon: const Icon(Icons.refresh),
              label: const Text("Update Sidebar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSearchRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blueGrey.shade50,
      child: Row(
        children: [
          _dateTextField(_startDateController, "From Date"),
          _timeTextField(_startTimeController, "Start Time"),

          const SizedBox(width: 20),
          const Text(" TO ", style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 20),

          _dateTextField(_endDateController, "To Date"),
          _timeTextField(_endTimeController, "End Time"),

          SizedBox(width: 20),

          // --- Search Button ---
          ElevatedButton(
            onPressed: () {
              // TextField မှ အချိန်များကို ယူပြီး DateTime ပြုလုပ်ခြင်း
              final start = _combineDateAndTime(
                _selectedDateRange!.start,
                _startTimeController.text,
              );
              final end = _combineDateAndTime(_selectedDateRange!.end, _endTimeController.text);

              print("Start: $start, End: $end");
              _searchSalesByDate(start, end);
              _fetchSysControlByRange(start, end);
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Row(children: [Icon(Icons.search), SizedBox(width: 8), Text("Search")]),
          ),

          const Spacer(),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // List<SaleData> salesList = _salesData.map((x) => SaleData.fromMap(x)).toList();
                  exportSaleDataReport(
                    _salesData.toList(),
                    AppConfig.stationName,
                    "${DateFormat('dd-MM-yyyy').format(_startDate)} ${_startTimeController.text}",
                    "${DateFormat('dd-MM-yyyy').format(_endDate)} ${_endTimeController.text}",
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.data_thresholding_rounded),
                    SizedBox(width: 8),
                    Text("Pump By Sale Report"),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 50, child: const Text("From ")),
                      Text(":  "),
                      Text(
                        "${DateFormat('dd-MM-yyyy').format(_startDate)} ${_startTimeController.text}",
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      SizedBox(width: 50, child: const Text("To ")),
                      Text(":  "),
                      Text(
                        "${DateFormat('dd-MM-yyyy').format(_endDate)} ${_endTimeController.text}",
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      SizedBox(width: 50, child: Text("Record")),
                      Text(":  "),
                      Text("${_salesData.length}"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            if (d != null)
              setState(() {
                _selectedDateRange = DateTimeRange(start: d, end: _selectedDateRange!.end);
                controller.text = DateFormat("dd-MM-yyyy").format(d);
              });
          },
          icon: const Icon(Icons.calendar_month),
          tooltip: "From Date",
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              hintText: "dd-mm-yyyy",
              border: const OutlineInputBorder(),
              counterText: "",
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
                    offset: currentOffset <= formatted.length ? currentOffset : formatted.length,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

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

              if (digits.length >= 2)
                hh = digits.substring(0, 2);
              else
                hh = digits.padLeft(2, '0');

              if (digits.length >= 4)
                mm = digits.substring(2, 4);
              else if (digits.length > 2)
                mm = digits.substring(2).padLeft(2, '0');

              if (digits.length >= 6)
                ss = digits.substring(4, 6);
              else if (digits.length > 4)
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
                    offset: currentOffset <= formatted.length ? currentOffset : formatted.length,
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

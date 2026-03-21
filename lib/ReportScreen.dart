import 'dart:async';
import 'dart:convert';

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
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
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

  final List<dynamic> _salesData = [];

  DateTimeRange? _selectedDateRange; // Date Range
  // Map<String, dynamic>? _sysControl;
  List<dynamic> _sysControlList = []; // List to hold API response
  bool isLoadingSidebar = false; // Sidebar loading state

  List<Map<String, dynamic>> _stations = [];
  String? _selectedStationId;

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

  // Table Filter & Sort State
  String _searchVoucher = "";
  String _searchVehicle = "";
  String _filterFuelType = "ALL";
  String _filterSaleType = "ALL";
  bool _sortAscending = false;

  // Derived filtered data
  List<dynamic> get _filteredSalesData {
    List<dynamic> filtered = List.from(_salesData);

    // 1. Filter by Voucher
    if (_searchVoucher.isNotEmpty) {
      filtered = filtered
          .where(
            (sale) => sale['VocNo'].toString().toLowerCase().contains(
              _searchVoucher.toLowerCase(),
            ),
          )
          .toList();
    }

    // 2. Filter by Vehicle
    if (_searchVehicle.isNotEmpty) {
      filtered = filtered
          .where(
            (sale) => (sale['Vehical_No'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchVehicle.toLowerCase()),
          )
          .toList();
    }

    // 3. Filter by Fuel Type
    if (_filterFuelType != "ALL") {
      filtered = filtered
          .where(
            (sale) =>
                (sale['FuelTypeName'] ?? '').toString() == _filterFuelType,
          )
          .toList();
    }

    // 4. Filter by Sale Type
    if (_filterSaleType != "ALL") {
      filtered = filtered
          .where(
            (sale) =>
                (sale['Sale_Type_name'] ?? '').toString() == _filterSaleType,
          )
          .toList();
    }

    // 5. Sort by Date
    filtered.sort((a, b) {
      try {
        DateTime dtA = _parseServerDateTime(a['S_Date']);
        DateTime dtB = _parseServerDateTime(b['S_Date']);
        return _sortAscending ? dtA.compareTo(dtB) : dtB.compareTo(dtA);
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

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

  /// Parses date string from server. Handles cases where 'Z' might be missing.
  DateTime _parseServerDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      // Treat the server string as local time if no timezone indicator is present
      // (This avoids the 6.5h offset since the server returns MMT strings)
      if (dateStr.contains(' ') && !dateStr.contains('T')) {
        dateStr = dateStr.replaceFirst(' ', 'T');
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint("Date Parse Error ($dateStr): $e");
      return DateTime.now();
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
    // ၃။ Station List ကိုသာ Initialize လုပ်ခြင်း (Data မခေါ်သေးပါ)
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    try {
      final response = await supabase
          .from('stations')
          .select('station_id, name')
          .order('name');

      if (mounted) {
        setState(() {
          _stations = List<Map<String, dynamic>>.from(response);
          // HO User (level 1) သို့မဟုတ် Supervisor (level 2) ဖြစ်လျှင် ALL STATIONS ထည့်ပေးမယ်
          if (AppConfig.currentUserLevel == 1 ||
              AppConfig.currentUserLevel == 2) {
            _stations.insert(0, {'station_id': 'ALL', 'name': 'ALL STATIONS'});
          }
          // Default stationId ကို null ထားမယ် (User ကို ရွေးခိုင်းမယ်)
          _selectedStationId = null;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    }
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
    DateTime startDT = _parseServerDateTime(
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
      endDT = _parseServerDateTime(
        _sysControlList[sortedIndices.last]['Sdate'],
      );
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
    if (_selectedStationId == null) {
      _showStationRequiredSnackBar();
      return;
    }
    // Use Local time for API parameters (as server expects MMT)
    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    // Node.js API Route (Search endpoint ကို သုံးထားပါသည်)

    // စတင်ချိန်မှာ Loading True နဲ့ 0% ပို့လိုက်မယ်
    salesStreamController.add(
      SalesLoadStatus(data: [], progress: 0.0, isLoading: true),
    );

    _salesData.clear();

    try {
      if (_selectedStationId == 'ALL') {
        // Initialize station progress list
        final targetStations = _stations
            .where((s) => s['station_id'] != 'ALL')
            .toList();
        List<Map<String, dynamic>> progressList = targetStations
            .map(
              (s) => {
                'station_id': s['station_id'],
                'name': s['name'],
                'status': 'pending', // pending, loading, done
              },
            )
            .toList();

        for (int i = 0; i < targetStations.length; i++) {
          final sId = targetStations[i]['station_id'];
          final sName = targetStations[i]['name'];

          // Update status to loading
          progressList[i]['status'] = 'loading';
          salesStreamController.add(
            SalesLoadStatus(
              data: _salesData,
              progress: i / targetStations.length,
              isLoading: true,
              stationProgress: progressList,
            ),
          );

          // API Call for this station
          final stationUrl =
              '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr&stationId=$sId';

          final originalId = AppConfig.stationId;
          final originalDb = AppConfig.database;
          AppConfig.stationId = sId;
          AppConfig.database = sId;

          List<dynamic> stationSales = [];
          await fetchWithProgress(
            stationUrl,
            stationSales,
            salesStreamController,
            stationProgress: progressList,
            stayLoading: i < targetStations.length - 1,
          );

          AppConfig.stationId = originalId;
          AppConfig.database = originalDb;

          for (var sale in stationSales) {
            sale['station_id'] = sId;
            sale['station_name'] = sName;
            // Normalize Date to Local for sorting and display
            if (sale['S_Date'] != null) {
              sale['S_Date'] = _parseServerDateTime(sale['S_Date']).toString();
            }
          }

          _salesData.addAll(stationSales);

          // Update status to done
          progressList[i]['status'] = 'done';

          salesStreamController.add(
            SalesLoadStatus(
              data: _salesData,
              progress: (i + 1) / targetStations.length,
              isLoading: i < targetStations.length - 1,
              stationProgress: progressList,
            ),
          );
        }
      } else {
        // Specific station
        final url =
            '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr&stationId=$_selectedStationId';
        final originalId = AppConfig.stationId;
        final originalDb = AppConfig.database;
        AppConfig.stationId = _selectedStationId!;
        AppConfig.database = _selectedStationId!;

        await fetchWithProgress(url, _salesData, salesStreamController);

        // Add station info and normalize dates
        final sName = _stations.firstWhere(
          (s) => s['station_id'] == _selectedStationId,
        )['name'];
        for (var sale in _salesData) {
          sale['station_id'] = _selectedStationId;
          sale['station_name'] = sName;
          if (sale['S_Date'] != null) {
            // We need to be careful as _salesData might have been populated by fetchWithProgress
            // already. But here _salesData was empty before fetchWithProgress in this branch.
            // Actually _salesData.clear() was called @ 272.
            sale['S_Date'] = _parseServerDateTime(sale['S_Date']).toString();
          }
        }

        AppConfig.stationId = originalId;
        AppConfig.database = originalDb;
      }

      // Sync System Control Logs as well
      _fetchSysControlByRange(start, end);
    } catch (e) {
      debugPrint("Sales Fetch Error: $e");
    }
  }

  // Sidebar (System Control Logs) အတွက် Data Fetching
  Future<void> _fetchSysControlByRange(DateTime start, DateTime end) async {
    if (_selectedStationId == null) return;
    setState(() => isLoadingSidebar = true);
    _sysControlList.clear();

    // Use Local time for API parameters (as server expects MMT)
    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    try {
      if (_selectedStationId == 'ALL') {
        final targetStations = _stations
            .where((s) => s['station_id'] != 'ALL')
            .toList();
        for (var station in targetStations) {
          final sId = station['station_id'];
          final sName = station['name'];

          final url = Uri.parse(
            '${AppConfig.apiUrl}/api/system-control/search?start=$startStr&end=$endStr&stationId=$sId',
          );

          final originalId = AppConfig.stationId;
          final originalDb = AppConfig.database;
          AppConfig.stationId = sId;
          AppConfig.database = sId;

          final response = await http.get(url, headers: AppConfig.headers);
          AppConfig.stationId = originalId;
          AppConfig.database = originalDb;

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            for (var item in data) {
              item['station_id'] = sId;
              item['station_name'] = sName;
              if (item['Sdate'] != null) {
                item['Sdate'] = _parseServerDateTime(
                  item['Sdate'].toString(),
                ).toString();
              }
            }
            _sysControlList.addAll(data);
          }
        }
        setState(() {});
      } else {
        final url = Uri.parse(
          '${AppConfig.apiUrl}/api/system-control/search?start=$startStr&end=$endStr&stationId=$_selectedStationId',
        );
        final originalId = AppConfig.stationId;
        final originalDb = AppConfig.database;
        AppConfig.stationId = _selectedStationId!;
        AppConfig.database = _selectedStationId!;
        final response = await http.get(url, headers: AppConfig.headers);
        AppConfig.stationId = originalId;
        AppConfig.database = originalDb;

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final sName = _stations.firstWhere(
            (s) => s['station_id'] == _selectedStationId,
          )['name'];
          for (var item in data) {
            item['station_id'] = _selectedStationId;
            item['station_name'] = sName;
            if (item['Sdate'] != null) {
              item['Sdate'] = _parseServerDateTime(
                item['Sdate'].toString(),
              ).toString();
            }
          }
          setState(() {
            _sysControlList = data;
          });
        }
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

  Widget _fieldSearchInput(String hint, Function(String) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 30,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white24 : Colors.grey,
            fontSize: 10,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _fieldDropdownFilter(
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white : Colors.black,
          ),
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
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
    if (_selectedStationId == null) {
      _showStationRequiredSnackBar();
      return;
    }

    final dynamicUrl = '$apiUrl?stationId=$_selectedStationId';

    // စတင်ချိန်မှာ Loading True နဲ့ 0% ပို့လိုက်မယ်
    salesStreamController.add(
      SalesLoadStatus(data: [], progress: 0.0, isLoading: true),
    );

    final originalId = AppConfig.stationId;
    final originalDb = AppConfig.database;
    AppConfig.stationId = _selectedStationId!;
    AppConfig.database = _selectedStationId!;

    try {
      final List<dynamic> latestSales = [];
      await fetchWithProgress(dynamicUrl, latestSales, salesStreamController);

      // Normalize dates and add station info
      for (var sale in latestSales) {
        if (sale['S_Date'] != null) {
          sale['S_Date'] = _parseServerDateTime(sale['S_Date']).toString();
        }
        sale['station_id'] = _selectedStationId;
        sale['station_name'] = AppConfig.stationName;
      }

      _salesData.clear();
      _salesData.addAll(latestSales);
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      AppConfig.stationId = originalId;
      AppConfig.database = originalDb;
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
              SalesLoadStatus(data: [], progress: 0.0, isLoading: false);

          final isMobile = MediaQuery.of(context).size.width < 1000;

          return Stack(
            children: [
              isMobile
                  ? ListView(
                      children: [
                        _buildDateSearchRow(isMobile, status.data),
                        if (_selectedStationId != null) ...[
                          SummaryView(
                            saleSummaryTable: _buildTypeSummaryTable(isMobile),
                            fuelSummaryTable: _buildFuelSummaryTable(isMobile),
                            stationSummaryTable: _selectedStationId == 'ALL'
                                ? _buildStationSummaryTable(isMobile)
                                : null,
                          ),
                          _buildHeaderInfo(isMobile),
                          _salesData.isEmpty
                              ? _buildEmptyState()
                              : _buildMobileShowDetailButton(status.data),
                        ] else
                          _buildInitialSelectStationState(),
                      ],
                    )
                  : Column(
                      children: [
                        _buildDateSearchRow(isMobile, status.data),
                        if (_selectedStationId != null) ...[
                          SummaryView(
                            saleSummaryTable: _buildTypeSummaryTable(isMobile),
                            fuelSummaryTable: _buildFuelSummaryTable(isMobile),
                            stationSummaryTable: _selectedStationId == 'ALL'
                                ? _buildStationSummaryTable(isMobile)
                                : null,
                          ),
                          _buildHeaderInfo(isMobile),
                          Expanded(
                            flex: 1,
                            child: _salesData.isEmpty
                                ? _buildEmptyState()
                                : _buildDataTable(
                                    status.data,
                                    status.isLoading,
                                  ),
                          ),
                        ] else
                          Expanded(child: _buildInitialSelectStationState()),
                      ],
                    ),
              Visibility(
                visible: status.isLoading,
                child: ProgressOverlay(
                  progress: status.progress,
                  currentCount: status.data.length,
                  stationProgress: status.stationProgress,
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
  Widget _buildDataTable(List<dynamic> rawData, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? StyleConstants.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // Use filtered data
    final data = _filteredSalesData;

    // Dynamic Filter Options
    final fuelTypes = [
      "ALL",
      ..._salesData
          .map((s) => s['FuelTypeName']?.toString() ?? 'Unknown')
          .toSet(),
    ];
    final saleTypes = [
      "ALL",
      ..._salesData
          .map((s) => s['Sale_Type_name']?.toString() ?? 'Unknown')
          .toSet(),
    ];

    return Column(
      children: [
        // ၁။ Header & Filter အပိုင်း
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 1400,
            decoration: BoxDecoration(
              color: headerColor,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.teal).withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                // Main Header Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('No', 1, textColor),
                      _buildHeaderCell('Station', 2, textColor),
                      _buildHeaderCell('Voucher No', 2, textColor),
                      _buildHeaderCell('Fuel Type', 2, textColor),
                      _buildHeaderCell('Price', 2, textColor),
                      // Sorting Toggle for Date & Time
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _sortAscending = !_sortAscending),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: Colors.teal,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildHeaderCell('Vehicle No', 2, textColor),
                      _buildHeaderCell('Sale Type', 2, textColor),
                      _buildHeaderCell('Liter', 2, textColor),
                      _buildHeaderCell('Amount', 2, textColor),
                      _buildHeaderCell('Action', 2, textColor),
                    ],
                  ),
                ),
                // Filter Search Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black12 : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(
                        color: (isDark ? Colors.white : Colors.teal)
                            .withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 1, child: SizedBox()), // No
                      const Expanded(flex: 2, child: SizedBox()), // Station
                      // Voucher Search
                      Expanded(
                        flex: 2,
                        child: _fieldSearchInput(
                          "Search Voucher",
                          (val) => setState(() => _searchVoucher = val),
                        ),
                      ),
                      // Fuel Type Filter
                      Expanded(
                        flex: 2,
                        child: _fieldDropdownFilter(
                          _filterFuelType,
                          fuelTypes,
                          (val) => setState(() => _filterFuelType = val!),
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()), // Price
                      const Expanded(flex: 3, child: SizedBox()), // Date
                      // Vehicle Search
                      Expanded(
                        flex: 2,
                        child: _fieldSearchInput(
                          "Search Vehicle",
                          (val) => setState(() => _searchVehicle = val),
                        ),
                      ),
                      // Sale Type Filter
                      Expanded(
                        flex: 2,
                        child: _fieldDropdownFilter(
                          _filterSaleType,
                          saleTypes,
                          (val) => setState(() => _filterSaleType = val!),
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()), // Liter
                      const Expanded(flex: 2, child: SizedBox()), // Amount
                      const Expanded(flex: 2, child: SizedBox()), // Action
                    ],
                  ),
                ),
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
                    width: 1400, // Fixed width for horizontal scrolling
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
                            : (isDark
                                  ? StyleConstants.darkSurface
                                  : Colors.white);
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
                                    (isDark
                                            ? Colors.white
                                            : Colors.grey.shade300)
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
                                '${sale['station_name'] ?? '-'} (${sale['station_id'] ?? '-'})',
                                2,
                                isText: true,
                              ),
                              _buildTableCell(
                                '${sale['VocNo']}',
                                2,
                                isText: true,
                              ), // Invoice No
                              dataCell(
                                "${sale['FuelTypeName']}",
                                150,
                                cardColor: getFuelColor(
                                  sale['FuelTypeName'] ?? '',
                                ),
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
                                ).format(_parseServerDateTime(sale['S_Date'])),
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
                                  double.tryParse(
                                        sale['TotalPrice'].toString(),
                                      ) ??
                                      0,
                                ),
                                2,
                                isNumeric: true,
                              ),
                              sale['Sale_Type_name'] == 'Cash Sale' ||
                                      sale['Sale_Type_name'] == 'ePayment'
                                  ? _buildTableCell(
                                      CheckAlreadyCollectedReport(
                                        sale: sale,
                                        supabase: supabase,
                                      ),
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

    return SizedBox(
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

    return SizedBox(
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
            Icon(
              Icons.list_alt_rounded,
              size: 64,
              color: Colors.teal.withOpacity(0.5),
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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

  Widget _buildInitialSelectStationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 80,
              color: Colors.teal.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              "ကျေးဇူးပြု၍ Station အရင်ရွေးချယ်ပါ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "အစီရင်ခံစာများကြည့်ရှုရန် အပေါ်ရှိ Station Selector မှ\nသက်ဆိုင်ရာ Station ကို ရွေးချယ်ပေးပါ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color getSaleTypeColor(String? typeName) {
    switch (typeName?.toUpperCase()) {
      case 'CASH SALE':
        return Colors.green;
      case 'CREDIT SALE':
        return Colors.orange;
      case 'FOC':
        return Colors.red;
      case 'EPAYMENT':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  Color getFuelColor(String fuelName) {
    if (fuelName.contains('92')) return Colors.orange;
    if (fuelName.contains('95')) return Colors.red;
    if (fuelName.contains('Diesel')) return Colors.green;
    if (fuelName.contains('Premium')) return Colors.blue;
    return Colors.blueGrey;
  }

  // Sidebar Widget
  Widget _buildRightSidebar() {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: isMobile ? 300 : 350,
      backgroundColor: isDark ? StyleConstants.darkBg : StyleConstants.lightBg,
      child: Column(
        children: [
          // 1. Custom Header with Glassmorphism
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF1B4F72), const Color(0xFF2C3E50)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.history_toggle_off,
                    size: 150,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Control Logs",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Date Range Badge
                        InkWell(
                          onTap: () => _pickDateRange(context),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            opacity: 0.1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit,
                                  color: Colors.white54,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Search / Filter Logs bar (Optional - for future use)

          // 3. Log List
          Expanded(
            child: _sysControlList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.query_stats,
                          size: 48,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No logs found in this range",
                          style: TextStyle(color: Colors.grey.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onVerticalDragStart: (details) {
                      _dragStartY = details.localPosition.dy;
                      if (!HardwareKeyboard.instance.isShiftPressed) {
                        setState(() => _selectedIndices.clear());
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      double currentY = details.localPosition.dy;
                      double itemHeight =
                          80.0; // Estimate for GlassContainer + Padding
                      int startIndex = (_dragStartY / itemHeight).floor();
                      int currentIndex = (currentY / itemHeight).floor();

                      setState(() {
                        int start = startIndex < currentIndex
                            ? startIndex
                            : currentIndex;
                        int end = startIndex > currentIndex
                            ? startIndex
                            : currentIndex;
                        for (int i = start; i <= end; i++) {
                          if (i >= 0 && i < _sysControlList.length) {
                            // Use reversed index logic for selection as well if needed
                            // However, since we are dragging over the visual list:
                            _selectedIndices.add(
                              _sysControlList.length - 1 - i,
                            );
                          }
                        }
                        _updateUpperRangeField();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                        itemCount: _sysControlList.length,
                        itemBuilder: (context, index) {
                          final reversedIndex =
                              _sysControlList.length - 1 - index;
                          final item = _sysControlList[reversedIndex];
                          bool isSelected = _selectedIndices.contains(
                            reversedIndex,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => _handleTap(reversedIndex),
                              borderRadius: BorderRadius.circular(
                                StyleConstants.borderRadius,
                              ),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(12),
                                opacity: isSelected
                                    ? 0.3
                                    : (isDark ? 0.1 : 0.05),
                                borderRadius: StyleConstants.borderRadius,
                                child: Row(
                                  children: [
                                    // Icon based on Option
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            (isSelected
                                                    ? Colors.blue
                                                    : Colors.teal)
                                                .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        item['soption'] == '1'
                                            ? Icons.settings
                                            : Icons.info_outline,
                                        size: 20,
                                        color: isSelected
                                            ? Colors.blueAccent
                                            : Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(
                                                  _parseServerDateTime(
                                                    item['Sdate'].toString(),
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? (isDark
                                                            ? Colors.blueAccent
                                                            : Colors.blue)
                                                      : (isDark
                                                            ? Colors.white
                                                            : Colors.black87),
                                                ),
                                              ),
                                              Text(
                                                item['soption'].toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.black38,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('HH:mm:ss').format(
                                                  _parseServerDateTime(
                                                    item['Sdate'].toString(),
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  letterSpacing: 0.5,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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
      // Start ကို 00:00:00 နှင့် End ကို 23:59:59 ဟု သတ်မှတ်မည်
      final start = DateTime(
        newRange.start.year,
        newRange.start.month,
        newRange.start.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        newRange.end.year,
        newRange.end.month,
        newRange.end.day,
        23,
        59,
        59,
      );
      final adjustedRange = DateTimeRange(start: start, end: end);

      setState(() {
        _selectedDateRange = adjustedRange;
      });
      // Data ကို ချက်ချင်း ပြန်ခေါ်မယ်
      _fetchSysControlByRange(adjustedRange.start, adjustedRange.end);
    }
  }

  Widget _buildDateSearchRow(bool isMobile, List<dynamic> data) {
    if (isMobile) {
      return _buildMobileSelectionView(data);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? StyleConstants.darkBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Station Selector
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SELECT STATION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStationSelector(false),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // 2. Start Date & Time
                Expanded(
                  flex: 3,
                  child: _buildDateTimeSegment(
                    title: "START DATE & TIME",
                    dateController: _startDateController,
                    timeController: _startTimeController,
                    icon: Icons.play_arrow_rounded,
                    color: Colors.green,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                // 3. End Date & Time
                Expanded(
                  flex: 3,
                  child: _buildDateTimeSegment(
                    title: "END DATE & TIME",
                    dateController: _endDateController,
                    timeController: _endTimeController,
                    icon: Icons.stop_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 24),
                // 4. Action Buttons
                _buildDesktopActions(isMobile),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildRecordSummary(_filteredSalesData, false)),
              if (_searchVoucher.isNotEmpty ||
                  _searchVehicle.isNotEmpty ||
                  _filterFuelType != "ALL" ||
                  _filterSaleType != "ALL")
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchVoucher = "";
                        _searchVehicle = "";
                        _filterFuelType = "ALL";
                        _filterSaleType = "ALL";
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text("CLEAR FILTERS"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(bool isMobile) {
    return Row(
      children: [
        Column(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final start = _combineDateAndTime(
                  _selectedDateRange!.start,
                  _startTimeController.text,
                );
                final end = _combineDateAndTime(
                  _selectedDateRange!.end,
                  _endTimeController.text,
                );
                await _searchSalesByDate(start, end);
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text("SEARCH"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchLatestSales,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text("LATEST 20"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportDetail(),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text("DETAIL"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _exportSummary(),
              icon: const Icon(Icons.summarize_outlined, size: 18),
              label: const Text("SUMMARY"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
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
          _buildStationSelector(true),
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
                        child: Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Colors.grey,
                        ),
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
                    final start = _combineDateAndTime(
                      _selectedDateRange!.start,
                      _startTimeController.text,
                    );
                    final end = _combineDateAndTime(
                      _selectedDateRange!.end,
                      _endTimeController.text,
                    );
                    await _fetchInitialData(start, end);
                  },
                  icon: const Icon(Icons.search),
                  label: const Text("SEARCH NOW"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelector(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 250,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: isMobile ? const EdgeInsets.only(bottom: 16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStationId,
          isExpanded: true,
          icon: const Icon(Icons.location_on, color: Colors.teal),
          items: _stations.map((station) {
            return DropdownMenuItem<String>(
              value: station['station_id'],
              child: Text(
                station['name'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStationId = value;
            });
            if (value != null) {
              final start = _combineDateAndTime(
                _selectedDateRange!.start,
                _startTimeController.text,
              );
              final end = _combineDateAndTime(
                _selectedDateRange!.end,
                _endTimeController.text,
              );
              _fetchInitialData(start, end);
              _fetchSysControlByRange(start, end);
            }
          },
        ),
      ),
    );
  }

  // Station Summary Table
  Widget _buildStationSummaryTable(bool isMobile) {
    Map<String, Map<String, dynamic>> stationSummary = {};

    for (var sale in _salesData) {
      String sId = sale['station_id'] ?? 'Unknown';
      String sName = sale['station_name'] ?? 'Unknown';
      double amount = double.tryParse(sale['TotalPrice'].toString()) ?? 0.0;
      double liters = double.tryParse(sale['SALELITER'].toString()) ?? 0.0;

      if (stationSummary.containsKey(sId)) {
        stationSummary[sId]!['amount'] =
            stationSummary[sId]!['amount'] + amount;
        stationSummary[sId]!['liters'] =
            stationSummary[sId]!['liters'] + liters;
      } else {
        stationSummary[sId] = {
          'name': sName,
          'amount': amount,
          'liters': liters,
        };
      }
    }

    final sortedEntries = stationSummary.entries.toList()
      ..sort((a, b) => b.value['amount'].compareTo(a.value['amount']));

    return SizedBox(
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
                    Colors.green.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Station',
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
                            '${entry.value['name']} (${entry.key})',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            entry.value['liters'].toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            NumberFormat('#,###').format(entry.value['amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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

  Widget _buildDateTimeSegment({
    required String title,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => _pickDateForController(
                          dateController,
                          title.contains("START"),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DATE",
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateController.text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TIME",
                            style: TextStyle(
                              fontSize: 8,
                              color: isDark ? Colors.white54 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: TextField(
                              controller: timeController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
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
      ),
    );
  }

  Future<void> _pickDateForController(
    TextEditingController controller,
    bool isStart,
  ) async {
    DateTime initial = isStart
        ? _selectedDateRange!.start
        : _selectedDateRange!.end;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedDateRange = DateTimeRange(
            start: picked,
            end: _selectedDateRange!.end,
          );
        } else {
          _selectedDateRange = DateTimeRange(
            start: _selectedDateRange!.start,
            end: picked,
          );
        }
        controller.text = DateFormat("dd-MM-yyyy").format(picked);
      });
    }
  }

  Future<void> _exportDetail() async {
    if (_selectedStationId == null) {
      _showStationRequiredSnackBar();
      return;
    }
    salesStreamController.add(
      SalesLoadStatus(data: _salesData, progress: 0.0, isLoading: true),
    );
    try {
      await exportSaleDetailReport(List<Map<String, dynamic>>.from(_salesData));
    } finally {
      salesStreamController.add(
        SalesLoadStatus(data: _salesData, progress: 1.0, isLoading: false),
      );
    }
  }

  void _exportSummary() {
    if (_selectedStationId == null) {
      _showStationRequiredSnackBar();
      return;
    }
    exportSaleDataReport(
      _salesData.toList(),
      AppConfig.stationName,
      "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} ${_startTimeController.text}",
      "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)} ${_endTimeController.text}",
    );
  }

  void _showStationRequiredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ကျေးဇူးပြု၍ Station အရင်ရွေးချယ်ပါ"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRecordSummary(List<dynamic> data, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        _infoRow(
          "From",
          "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start)} ${_startTimeController.text}",
        ),
        _infoRow(
          "To",
          "${DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end)} ${_endTimeController.text}",
        ),
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
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(":  $value"),
        ],
      ),
    );
  }

  // Helper: "dd-mm-yyyy" -> "yyyy-mm-dd"
  String convertToSqlDate(String dateStr) {
    List<String> p = dateStr.split('-');
    return "${p[2]}-${p[1]}-${p[0]}"; // Year-Month-Day
  }
}

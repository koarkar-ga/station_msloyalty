import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/BuildProgessOverlay.dart';
import 'package:station_msloyalty/Helper/FetchWithProgress.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/PumpBySaleReport.dart';
import 'package:station_msloyalty/Helper/SaleDetailReport.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
import 'package:station_msloyalty/summary_view.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
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
  List<String> _selectedStationIds = [];

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
  final TextEditingController _voucherSearchController =
      TextEditingController();
  final TextEditingController _vehicleSearchController =
      TextEditingController();
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

  List<String> get _fuelTypes {
    final types = _salesData
        .map((e) => (e['FuelTypeName'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return ["ALL", ...types];
  }

  List<String> get _saleTypes {
    final types = _salesData
        .map((e) => (e['Sale_Type_name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return ["ALL", ...types];
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
          .select('station_id, name, region')
          .order('name');

      if (mounted) {
        setState(() {
          final allStations = List<Map<String, dynamic>>.from(
            response.map((e) => {...e, 'region': e['region'] ?? 'Other'}),
          );

          if (AppConfig.isHoConfig) {
            _stations = allStations;
            // HO User (level 1) သို့မဟုတ် Supervisor (level 2) ဖြစ်လျှင် ALL STATIONS ထည့်ပေးမယ်
            if (AppConfig.currentUserLevel == 1 ||
                AppConfig.currentUserLevel == 2) {
              _stations.insert(0, {
                'station_id': 'ALL',
                'name': 'ALL STATIONS',
              });
            }
            _selectedStationIds = [];
          } else {
            // In Station Mode, only show the current station
            _stations = allStations
                .where((s) => s['station_id'] == AppConfig.stationId)
                .toList();
            if (_stations.isEmpty) {
              // Fallback if current station not found in Supabase
              _stations = [
                {
                  'station_id': AppConfig.stationId,
                  'name': AppConfig.stationName,
                  'region': 'Local',
                },
              ];
            }
            _selectedStationIds = [AppConfig.stationId];
            // Fetch records automatically for the single station
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
            final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
            _fetchInitialData(todayStart, todayEnd);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupStationsByRegion() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var station in _stations) {
      if (station['station_id'] == 'ALL') continue;
      final region = station['region']?.toString() ?? 'Other';
      if (!grouped.containsKey(region)) {
        grouped[region] = [];
      }
      grouped[region]!.add(station);
    }
    return grouped;
  }

  // Helper to get actual list of station names/ids to fetch
  List<Map<String, dynamic>> _getEffectiveSelectedStations() {
    if (_selectedStationIds.contains('ALL')) {
      return _stations.where((s) => s['station_id'] != 'ALL').toList();
    }
    return _stations
        .where((s) => _selectedStationIds.contains(s['station_id']))
        .toList();
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
    _rangeTimeClosedController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _voucherSearchController.dispose();
    _vehicleSearchController.dispose();
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
    if (_selectedStationIds.isEmpty) {
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
      final List<Map<String, dynamic>> targetStations =
          _getEffectiveSelectedStations();

      // Initialize station progress list
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

        // API Call for this station - In Station mode, we don't want to override the database name with the station ID
        final stationUrl = AppConfig.isHoConfig
            ? '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr&stationId=$sId'
            : '${AppConfig.apiUrl}/api/sales/search?startDate=$startStr&endDate=$endStr';

        List<dynamic> stationSales = [];
        await fetchWithProgress(
          stationUrl,
          stationSales,
          salesStreamController,
          stationProgress: progressList,
          stayLoading: i < targetStations.length - 1,
          headers: {
            ...AppConfig.headers,
            if (AppConfig.isHoConfig)
              'x-station-id': sId, // Only override in HO mode
          },
        );

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

      // Sync System Control Logs as well
      _fetchSysControlByRange(start, end);
    } catch (e) {
      debugPrint("Sales Fetch Error: $e");
    }
  }

  // Sidebar (System Control Logs) အတွက် Data Fetching
  Future<void> _fetchSysControlByRange(DateTime start, DateTime end) async {
    if (_selectedStationIds.isEmpty) return;
    setState(() => isLoadingSidebar = true);
    _sysControlList.clear();

    // Use Local time for API parameters (as server expects MMT)
    final String startStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(start);
    final String endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

    try {
      final targetStations = _getEffectiveSelectedStations();
      for (var station in targetStations) {
        final sId = station['station_id'];
        final sName = station['name'];

        final url = Uri.parse(
          AppConfig.isHoConfig
              ? '${AppConfig.apiUrl}/api/system-control/search?start=$startStr&end=$endStr&stationId=$sId'
              : '${AppConfig.apiUrl}/api/system-control/search?start=$startStr&end=$endStr',
        );

        final response = await http.get(url, headers: {
          ...AppConfig.headers,
          if (AppConfig.isHoConfig) 'x-station-id': sId,
        });

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

    for (var sale in _filteredSalesData) {
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

    for (var sale in _filteredSalesData) {
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
    for (var sale in _filteredSalesData) {
      final type = sale['FuelTypeName'] ?? sale['Sale_Type_name'];
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
    if (_selectedStationIds.isEmpty) {
      _showStationRequiredSnackBar();
      return;
    }

    final targetStations = _getEffectiveSelectedStations();

    try {
      _salesData.clear();
      for (var station in targetStations) {
        final sId = station['station_id'];
        final dynamicUrl = AppConfig.isHoConfig
            ? '$apiUrl?stationId=$sId'
            : apiUrl;

        final List<dynamic> stationLatestSales = [];
        await fetchWithProgress(
          dynamicUrl,
          stationLatestSales,
          salesStreamController,
          headers: {
            ...AppConfig.headers,
            if (AppConfig.isHoConfig) 'x-station-id': sId,
          },
        );

        // Normalize dates and add station info
        for (var sale in stationLatestSales) {
          if (sale['S_Date'] != null) {
            sale['S_Date'] = _parseServerDateTime(sale['S_Date']).toString();
          }
          sale['station_id'] = sId;
          sale['station_name'] = station['name'];
        }
        _salesData.addAll(stationLatestSales);
      }
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
              SalesLoadStatus(data: [], progress: 0.0, isLoading: false);

          final isMobile = MediaQuery.of(context).size.width < 1100;

          return Stack(
            children: [
              isMobile ? _buildMobileView(status) : _buildDesktopView(status),
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

  // --- Layout Views ---

  Widget _buildMobileView(SalesLoadStatus status) {
    const bool isMobile = true;
    return ListView(
      children: [
        _buildDateSearchRow(isMobile, status.data),
        if (_selectedStationIds.isNotEmpty) ...[
          SummaryView(
            saleSummaryTable: _buildTypeSummaryTable(isMobile),
            fuelSummaryTable: _buildFuelSummaryTable(isMobile),
            stationSummaryTable:
                (_selectedStationIds.contains('ALL') ||
                    _selectedStationIds.length > 1)
                ? _buildStationSummaryTable(isMobile)
                : null,
          ),
          _buildHeaderInfo(isMobile),
          _salesData.isEmpty
              ? _buildEmptyState()
              : _buildShowDetailButton(status.data),
        ] else
          _buildInitialSelectStationState(),
      ],
    );
  }

  Widget _buildDesktopView(SalesLoadStatus status) {
    const bool isMobile = false;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          children: [
            _buildDateSearchRow(isMobile, status.data),
            if (_selectedStationIds.isNotEmpty) ...[
              SummaryView(
                saleSummaryTable: _buildTypeSummaryTable(isMobile),
                fuelSummaryTable: _buildFuelSummaryTable(isMobile),
                stationSummaryTable:
                    (_selectedStationIds.contains('ALL') ||
                        _selectedStationIds.length > 1)
                    ? _buildStationSummaryTable(isMobile)
                    : null,
              ),
              const SizedBox(height: 10),
              _buildHeaderInfo(isMobile),
              const SizedBox(height: 20),
              _salesData.isEmpty
                  ? _buildEmptyState()
                  : _buildShowDetailButton(status.data),
            ] else
              _buildInitialSelectStationState(),
          ],
        ),
      ),
    );
  }

  // Build Header Information
  Widget _buildHeaderInfo(bool isMobile) {
    double grandTotalLiter = _filteredSalesData.fold(
      0,
      (prev, element) =>
          prev + (double.tryParse(element['SALELITER'].toString()) ?? 0),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: (isDark ? StyleConstants.darkBg : Colors.blueGrey.shade50)
            .withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
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
            "${NumberFormat('#,###').format(_filteredSalesData.fold<num>(0, (num sum, item) => sum + (item['TotalPrice'] ?? 0)))} Ks",
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

  Widget _buildShowDetailButton(List<dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_rounded,
              size: 64,
              color: Colors.teal.withValues(alpha: 0.5),
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
                        salesData: _filteredSalesData,
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
              color: Colors.teal.withValues(alpha: 0.5),
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

  IconData getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('cycle') || cat.contains('bike')) return Icons.motorcycle;
    if (cat.contains('car') ||
        cat.contains('passenger') ||
        cat.contains('taxi'))
      return Icons.directions_car;
    if (cat.contains('truck') || cat.contains('lorry'))
      return Icons.local_shipping;
    if (cat.contains('bus')) return Icons.directions_bus;
    if (cat.contains('machinery') || cat.contains('tractor'))
      return Icons.construction;
    if (cat.contains('tanker')) return Icons.oil_barrel;
    if (cat.contains('company')) return Icons.business;
    if (cat.contains('factory')) return Icons.factory;
    return Icons.category_outlined;
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
                    children: AppConfig.isHoConfig
                        ? [
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
                          ]
                        : [],
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
          const SizedBox(height: 12),
          // Search Filters Row
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  controller: _voucherSearchController,
                  hint: "Search Voucher No",
                  icon: Icons.receipt_long_rounded,
                  onChanged: (val) => setState(() => _searchVoucher = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSearchField(
                  controller: _vehicleSearchController,
                  hint: "Search Vehicle No",
                  icon: Icons.directions_car_rounded,
                  onChanged: (val) => setState(() => _searchVehicle = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  value: _filterFuelType,
                  items: _fuelTypes,
                  label: "Fuel Type",
                  icon: Icons.local_gas_station_rounded,
                  onChanged: (val) => setState(() => _filterFuelType = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  value: _filterSaleType,
                  items: _saleTypes,
                  label: "Sale Type",
                  icon: Icons.payments_rounded,
                  onChanged: (val) => setState(() => _filterSaleType = val!),
                ),
              ),
            ],
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
                        _voucherSearchController.clear();
                        _vehicleSearchController.clear();
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
          if (AppConfig.isHoConfig) _buildStationSelector(true),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchField(
                  controller: _voucherSearchController,
                  hint: "Search Voucher No",
                  icon: Icons.receipt_long_rounded,
                  onChanged: (val) => setState(() => _searchVoucher = val),
                  isMobile: true,
                ),
                const SizedBox(height: 12),
                _buildSearchField(
                  controller: _vehicleSearchController,
                  hint: "Search Vehicle No",
                  icon: Icons.directions_car_rounded,
                  onChanged: (val) => setState(() => _searchVehicle = val),
                  isMobile: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filterFuelType,
                        items: _fuelTypes,
                        label: "Fuel Type",
                        icon: Icons.local_gas_station_rounded,
                        onChanged: (val) =>
                            setState(() => _filterFuelType = val!),
                        isMobile: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filterSaleType,
                        items: _saleTypes,
                        label: "Sale Type",
                        icon: Icons.payments_rounded,
                        onChanged: (val) =>
                            setState(() => _filterSaleType = val!),
                        isMobile: true,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
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

  void _showStationSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Stations"),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedStationIds = ['ALL'];
                            });
                          },
                          child: const Text("Select ALL"),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedStationIds = [];
                            });
                          },
                          child: const Text("Clear All"),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // 1. ALL STATIONS (if exists)
                          ..._stations
                              .where((s) => s['station_id'] == 'ALL')
                              .map((station) {
                                final sId = station['station_id'].toString();
                                final sName = station['name'] ?? '';
                                bool isAllSelected = _selectedStationIds
                                    .contains('ALL');

                                return CheckboxListTile(
                                  title: Text(
                                    sName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: isAllSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _selectedStationIds = val == true
                                          ? ['ALL']
                                          : [];
                                    });
                                  },
                                );
                              }),

                          const Divider(),

                          // 2. Grouped by Region
                          ..._groupStationsByRegion().entries.map((entry) {
                            final regionName = entry.key;
                            final regionStations = entry.value;

                            // Check if ALL stations in this region are selected
                            final regionStationIds = regionStations
                                .map((s) => s['station_id'].toString())
                                .toList();
                            bool isRegionFullySelected =
                                regionStationIds.isNotEmpty &&
                                regionStationIds.every(
                                  (id) => _selectedStationIds.contains(id),
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Region Header with Toggle
                                CheckboxListTile(
                                  title: Text(
                                    regionName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[700],
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  value: isRegionFullySelected,
                                  activeColor: Colors.teal,
                                  dense: true,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      _selectedStationIds.remove('ALL');
                                      if (val == true) {
                                        // Select all in region
                                        for (var id in regionStationIds) {
                                          if (!_selectedStationIds.contains(
                                            id,
                                          )) {
                                            _selectedStationIds.add(id);
                                          }
                                        }
                                      } else {
                                        // Deselect all in region
                                        _selectedStationIds.removeWhere(
                                          (id) => regionStationIds.contains(id),
                                        );
                                      }
                                    });
                                  },
                                ),

                                // Individual Stations (Indented)
                                ...regionStations.map((station) {
                                  final sName = station['name'] ?? '';
                                  final String sIdStr = station['station_id']
                                      .toString();
                                  bool isSelected = _selectedStationIds
                                      .contains(sIdStr);

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 24.0),
                                    child: CheckboxListTile(
                                      title: Text(
                                        sName,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      value: isSelected,
                                      dense: true,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          _selectedStationIds.remove('ALL');
                                          if (val == true) {
                                            _selectedStationIds.add(sIdStr);
                                          } else {
                                            _selectedStationIds.remove(sIdStr);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }),
                                const Divider(height: 1),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Apply Selection"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStationSelector(bool isMobile) {
    String displayText = "Select Station";
    if (_selectedStationIds.contains('ALL')) {
      displayText = "ALL STATIONS";
    } else if (_selectedStationIds.isNotEmpty) {
      if (_selectedStationIds.length == 1) {
        displayText = _stations.firstWhere(
          (s) => s['station_id'] == _selectedStationIds.first,
          orElse: () => {'name': 'Selected'},
        )['name'];
      } else {
        displayText = "${_selectedStationIds.length} Stations Selected";
      }
    }

    return InkWell(
      onTap: AppConfig.isHoConfig ? _showStationSelectionDialog : null,
      child: Container(
        width: isMobile ? double.infinity : 250,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: isMobile ? const EdgeInsets.only(bottom: 16) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.teal, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (AppConfig.isHoConfig)
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
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
                          InkWell(
                            onTap: () => _pickTimeForController(timeController),
                            child: SizedBox(
                              height: 25,
                              child: TextField(
                                controller: timeController,
                                enabled: false,
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
                              ),
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

  Future<void> _pickTimeForController(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateFormat("HH:mm:ss").parse(controller.text),
      ),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      });
    }
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    bool isMobile = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: isMobile ? 45 : 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: Colors.teal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool isMobile = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: isMobile ? 45 : 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : "ALL",
          items: items.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          hint: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Future<void> _exportDetail() async {
    if (_selectedStationIds.isEmpty) {
      _showStationRequiredSnackBar();
      return;
    }
    salesStreamController.add(
      SalesLoadStatus(data: _salesData, progress: 0.0, isLoading: true),
    );
    try {
      await exportSaleDetailReport(
        List<Map<String, dynamic>>.from(_filteredSalesData),
      );
    } finally {
      salesStreamController.add(
        SalesLoadStatus(data: _salesData, progress: 1.0, isLoading: false),
      );
    }
  }

  void _exportSummary() {
    if (_selectedStationIds.isEmpty) {
      _showStationRequiredSnackBar();
      return;
    }

    final stName = _selectedStationIds.contains('ALL')
        ? "ALL STATIONS"
        : _getEffectiveSelectedStations().map((e) => e['name']).join(", ");

    exportSaleDataReport(
      _filteredSalesData.toList(),
      stName,
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';

class StationComparisonData {
  final String stationId;
  final String stationName;
  final double totalLiter;
  final double totalAmount;

  StationComparisonData({
    required this.stationId,
    required this.stationName,
    required this.totalLiter,
    required this.totalAmount,
  });
}

class ComparisonReportScreen extends StatefulWidget {
  const ComparisonReportScreen({super.key});

  @override
  State<ComparisonReportScreen> createState() => _ComparisonReportScreenState();
}

class _ComparisonReportScreenState extends State<ComparisonReportScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  bool isTypeAmount = true; // true: Amount, false: Liters
  late TabController _tabController;

  // Filter selection state
  List<Map<String, dynamic>> _stations = [];
  String? _selectedStationId;
  String _selectedStationName = "";
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Data state for single station
  List<dynamic> _yoyRawData = [];
  List<dynamic> _selectedMonthDailyRaw = [];
  List<dynamic> _prevMonthDailyRaw = [];

  // YoY Monthly parsed data
  Map<int, List<double>> _yoyLiters = {};
  Map<int, List<double>> _yoyAmounts = {};

  // Daily MoM parsed data
  List<double> _selectedMonthDailyLiters = [];
  List<double> _selectedMonthDailyAmounts = [];
  List<double> _prevMonthDailyLiters = [];
  List<double> _prevMonthDailyAmounts = [];

  // Summary totals
  double _selectedMonthTotalLiter = 0.0;
  double _selectedMonthTotalAmount = 0.0;
  double _prevMonthTotalLiter = 0.0;
  double _prevMonthTotalAmount = 0.0;

  // All Stations comparison data
  List<StationComparisonData> _allStationsData = [];
  bool isLoadingAllStations = false;
  bool _isAllStationsAscending = false;
  String _allStationsSortBy = "amount"; // "amount" or "liter"

  final List<int> _years = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );
  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConfig.isHoConfig ? 3 : 2,
      vsync: this,
    );
    _initializeFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeFilters() async {
    setState(() => isLoading = true);
    await _fetchStations();

    // Default to the first station in the list
    if (_stations.isNotEmpty) {
      if (AppConfig.isHoConfig) {
        _selectedStationId = _stations.first['station_id'];
        _selectedStationName = _stations.first['name'];
      } else {
        // Locked to current station
        _selectedStationId = AppConfig.stationId;
        _selectedStationName = AppConfig.stationName;
      }
    }

    await _refreshData();
  }

  Future<void> _refreshData() async {
    await _fetchComparisonData();
    if (AppConfig.isHoConfig) {
      await _fetchAllStationsComparison();
    }
  }

  Future<void> _fetchStations() async {
    try {
      final response = await supabase
          .from('stations')
          .select('station_id, name, region')
          .order('name');

      setState(() {
        final allStations = List<Map<String, dynamic>>.from(response);
        if (AppConfig.isHoConfig) {
          _stations = allStations;
        } else {
          _stations = allStations
              .where((s) => s['station_id'] == AppConfig.stationId)
              .toList();
          if (_stations.isEmpty) {
            _stations = [
              {
                'station_id': AppConfig.stationId,
                'name': AppConfig.stationName,
                'region': 'Local',
              },
            ];
          }
        }
      });
    } catch (e) {
      debugPrint("Error fetching stations: $e");
      // Fallback local station configuration if Supabase fails
      setState(() {
        _stations = [
          {
            'station_id': AppConfig.stationId,
            'name': AppConfig.stationName,
            'region': 'Local',
          },
        ];
      });
    }
  }

  Future<void> _fetchComparisonData() async {
    if (_selectedStationId == null) return;
    setState(() => isLoading = true);

    final url = Uri.parse(
      '${AppConfig.apiUrl}/api/reports/comparison?year=$_selectedYear&month=$_selectedMonth&stationId=$_selectedStationId',
    );

    try {
      final response = await http.get(
        url,
        headers: {...AppConfig.headers, 'x-station-id': _selectedStationId!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _yoyRawData = data['yoy'] ?? [];
          _selectedMonthDailyRaw = data['selectedMonthDaily'] ?? [];
          _prevMonthDailyRaw = data['prevMonthDaily'] ?? [];

          _parseData();
        });
      } else {
        _showErrorSnackBar(
          "Failed to load comparison data: Server Error (${response.statusCode})",
        );
      }
    } catch (e) {
      debugPrint("Error fetching comparison data: $e");
      _showErrorSnackBar(
        "Error connecting to API server: Make sure API is online.",
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAllStationsComparison() async {
    if (!AppConfig.isHoConfig || _stations.isEmpty) return;

    setState(() => isLoadingAllStations = true);

    try {
      List<Future<StationComparisonData?>> futures = _stations.map((
        station,
      ) async {
        final sId = station['station_id'];
        final sName = station['name'] ?? 'Unknown Station';

        final url = Uri.parse(
          '${AppConfig.apiUrl}/api/reports/comparison?year=$_selectedYear&month=$_selectedMonth&stationId=$sId',
        );

        try {
          final response = await http.get(
            url,
            headers: {...AppConfig.headers, 'x-station-id': sId},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final dailyRaw = data['selectedMonthDaily'] ?? [];

            double totalLiter = 0.0;
            double totalAmount = 0.0;

            for (var item in dailyRaw) {
              totalLiter += (item['TotalLiter'] ?? 0.0).toDouble();
              totalAmount += (item['TotalAmount'] ?? 0.0).toDouble();
            }

            return StationComparisonData(
              stationId: sId,
              stationName: sName,
              totalLiter: totalLiter,
              totalAmount: totalAmount,
            );
          }
        } catch (e) {
          debugPrint("Error fetching comparison for station $sName: $e");
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);

      setState(() {
        _allStationsData = results.whereType<StationComparisonData>().toList();
        _sortAllStationsData();
      });
    } catch (e) {
      debugPrint("Error in _fetchAllStationsComparison: $e");
    } finally {
      setState(() => isLoadingAllStations = false);
    }
  }

  void _sortAllStationsData() {
    if (_allStationsSortBy == "amount") {
      if (_isAllStationsAscending) {
        _allStationsData.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
      } else {
        _allStationsData.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      }
    } else {
      if (_isAllStationsAscending) {
        _allStationsData.sort((a, b) => a.totalLiter.compareTo(b.totalLiter));
      } else {
        _allStationsData.sort((a, b) => b.totalLiter.compareTo(a.totalLiter));
      }
    }
  }

  void _parseData() {
    // 1. Initialize YoY maps for the selected year and the previous 2 years
    _yoyLiters.clear();
    _yoyAmounts.clear();
    for (int y = _selectedYear - 2; y <= _selectedYear; y++) {
      _yoyLiters[y] = List.generate(12, (_) => 0.0);
      _yoyAmounts[y] = List.generate(12, (_) => 0.0);
    }

    for (var item in _yoyRawData) {
      int y = item['SaleYear'] ?? 0;
      int m = item['SaleMonth'] ?? 0;
      double liter = (item['TotalLiter'] ?? 0.0).toDouble();
      double amount = (item['TotalAmount'] ?? 0.0).toDouble();

      if (_yoyLiters.containsKey(y) && m >= 1 && m <= 12) {
        _yoyLiters[y]![m - 1] = liter;
        _yoyAmounts[y]![m - 1] = amount;
      }
    }

    // 2. Parse daily data for selected month
    _selectedMonthDailyLiters = List.generate(31, (_) => 0.0);
    _selectedMonthDailyAmounts = List.generate(31, (_) => 0.0);
    _selectedMonthTotalLiter = 0.0;
    _selectedMonthTotalAmount = 0.0;

    for (var item in _selectedMonthDailyRaw) {
      int d = item['SaleDay'] ?? 0;
      double liter = (item['TotalLiter'] ?? 0.0).toDouble();
      double amount = (item['TotalAmount'] ?? 0.0).toDouble();

      if (d >= 1 && d <= 31) {
        _selectedMonthDailyLiters[d - 1] = liter;
        _selectedMonthDailyAmounts[d - 1] = amount;
        _selectedMonthTotalLiter += liter;
        _selectedMonthTotalAmount += amount;
      }
    }

    // 3. Parse daily data for previous month
    _prevMonthDailyLiters = List.generate(31, (_) => 0.0);
    _prevMonthDailyAmounts = List.generate(31, (_) => 0.0);
    _prevMonthTotalLiter = 0.0;
    _prevMonthTotalAmount = 0.0;

    for (var item in _prevMonthDailyRaw) {
      int d = item['SaleDay'] ?? 0;
      double liter = (item['TotalLiter'] ?? 0.0).toDouble();
      double amount = (item['TotalAmount'] ?? 0.0).toDouble();

      if (d >= 1 && d <= 31) {
        _prevMonthDailyLiters[d - 1] = liter;
        _prevMonthDailyAmounts[d - 1] = amount;
        _prevMonthTotalLiter += liter;
        _prevMonthTotalAmount += amount;
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      appBar: const MsAppBar(title: 'Comparison Report', showBackButton: true),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildFilterSection(isDark, isMobile),
                const SizedBox(height: 16),
                _buildToggleRow(isDark),
                const SizedBox(height: 16),
                _buildSummaryCards(isDark, isMobile),
                const SizedBox(height: 16),
                _buildTabBarSection(isDark),
                const SizedBox(height: 16),
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMoMTab(isDark),
                      _buildYoYTab(isDark),
                      if (AppConfig.isHoConfig) _buildAllStationsTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading || isLoadingAllStations)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(bool isDark) {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.monetization_on_outlined),
            label: Text("Amount (Ks)"),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.water_drop_outlined),
            label: Text("Liters (L)"),
          ),
        ],
        selected: {isTypeAmount},
        onSelectionChanged: (value) {
          setState(() {
            isTypeAmount = value.first;
          });
        },
      ),
    );
  }

  Widget _buildFilterSection(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? StyleConstants.darkSurface
            : StyleConstants.lightSurface,
        borderRadius: BorderRadius.circular(StyleConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          // Station Selector
          if (AppConfig.isHoConfig && _stations.length > 1)
            SizedBox(
              width: isMobile ? double.infinity : 250,
              child: DropdownButtonFormField<String>(
                value: _selectedStationId,
                decoration: const InputDecoration(
                  labelText: 'Station',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _stations.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['station_id'],
                    child: Text(s['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStationId = value;
                      _selectedStationName = _stations.firstWhere(
                        (s) => s['station_id'] == value,
                      )['name'];
                    });
                    _fetchComparisonData();
                  }
                },
              ),
            )
          else
            // Single Station configuration info
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.store_mall_directory_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedStationName.isEmpty
                      ? AppConfig.stationName
                      : _selectedStationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

          // Year and Month selectors
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Selector
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: _years.map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYear = value);
                      _refreshData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Month Selector
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_months[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                      _refreshData();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, bool isMobile) {
    double currentVal = isTypeAmount
        ? _selectedMonthTotalAmount
        : _selectedMonthTotalLiter;
    double prevVal = isTypeAmount
        ? _prevMonthTotalAmount
        : _prevMonthTotalLiter;

    double diff = currentVal - prevVal;
    double percentChange = prevVal == 0 ? 0.0 : (diff / prevVal) * 100;
    bool isPositive = diff >= 0;

    String labelText = isTypeAmount
        ? "Total Sales (Amount)"
        : "Total Sales (Volume)";
    String unit = isTypeAmount ? " Ks" : " L";
    String formattedCurrent = isTypeAmount
        ? NumberFormat('#,###').format(currentVal)
        : currentVal.toStringAsFixed(2);
    String formattedPrev = isTypeAmount
        ? NumberFormat('#,###').format(prevVal)
        : prevVal.toStringAsFixed(2);

    String monthName = _months[_selectedMonth - 1];
    String prevMonthName = _selectedMonth == 1
        ? _months[11]
        : _months[_selectedMonth - 2];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Current Month Card
        _buildMetricCard(
          isDark,
          isMobile,
          title: "$monthName $_selectedYear",
          value: "$formattedCurrent$unit",
          subtitle: labelText,
          icon: isTypeAmount ? Icons.monetization_on : Icons.water_drop,
          iconColor: const Color(0xFF10B981),
        ),
        // Previous Month Card
        _buildMetricCard(
          isDark,
          isMobile,
          title:
              "$prevMonthName ${_selectedMonth == 1 ? _selectedYear - 1 : _selectedYear}",
          value: "$formattedPrev$unit",
          subtitle: labelText,
          icon: isTypeAmount ? Icons.payments_outlined : Icons.opacity,
          iconColor: Colors.blueAccent,
        ),
        // MoM Growth Variance Card
        _buildMetricCard(
          isDark,
          isMobile,
          title: "Month-over-Month Growth",
          value: "${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%",
          subtitle: "${isPositive ? 'Increase' : 'Decrease'} vs. last month",
          icon: isPositive ? Icons.trending_up : Icons.trending_down,
          iconColor: isPositive ? Colors.green : Colors.red,
          customBadge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPositive ? "UP" : "DOWN",
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    bool isDark,
    bool isMobile, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? customBadge,
  }) {
    final double cardWidth = isMobile
        ? double.infinity
        : (MediaQuery.of(context).size.width - 64) / 3;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? StyleConstants.darkSurface
            : StyleConstants.lightSurface,
        borderRadius: BorderRadius.circular(StyleConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (customBadge != null) customBadge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? StyleConstants.darkSurface : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark
              ? StyleConstants.darkAccent
              : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade700,
        tabs: [
          const Tab(text: 'Month-over-Month Daily'),
          const Tab(text: 'Year-over-Year Monthly'),
          if (AppConfig.isHoConfig) const Tab(text: 'All Stations Comparison'),
        ],
      ),
    );
  }

  Widget _buildMoMTab(bool isDark) {
    // Compile daily values
    final currentList = isTypeAmount
        ? _selectedMonthDailyAmounts
        : _selectedMonthDailyLiters;
    final prevList = isTypeAmount
        ? _prevMonthDailyAmounts
        : _prevMonthDailyLiters;

    if (currentList.every((v) => v == 0) && prevList.every((v) => v == 0)) {
      return _buildEmptyState(
        "No sales records available for this month and last month.",
      );
    }

    final double maxVal = [
      ...currentList,
      ...prevList,
    ].reduce((curr, next) => curr > next ? curr : next);

    final double verticalInterval = maxVal > 0 ? (maxVal / 5) : 10.0;

    String currentMonthName = _months[_selectedMonth - 1];
    String prevMonthName = _selectedMonth == 1
        ? _months[11]
        : _months[_selectedMonth - 2];
    final String label = isTypeAmount ? "Amount" : "Volume";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? StyleConstants.darkSurface : StyleConstants.lightSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendIndicator(
                  currentMonthName,
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 24),
                _buildLegendIndicator(prevMonthName, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: verticalInterval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _formatAxisValue(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 45,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          int day = value.toInt() + 1;
                          if (day < 1 || day > 31)
                            return const SizedBox.shrink();
                          return Text(
                            "Day $day",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 30,
                  minY: 0,
                  maxY: maxVal * 1.15,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isCurrent = spot.barIndex == 0;
                          final monthLabel = isCurrent
                              ? currentMonthName
                              : prevMonthName;
                          final formattedVal = isTypeAmount
                              ? NumberFormat('#,###').format(spot.y)
                              : spot.y.toStringAsFixed(1);
                          final unit = isTypeAmount ? " Ks" : " L";

                          return LineTooltipItem(
                            "$monthLabel Day ${spot.x.toInt() + 1}\n$label: $formattedVal$unit",
                            TextStyle(
                              color: isCurrent
                                  ? const Color(0xFF10B981)
                                  : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Line 1: Selected Month (Current)
                    LineChartBarData(
                      spots: List.generate(
                        31,
                        (index) => FlSpot(index.toDouble(), currentList[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withOpacity(0.1),
                      ),
                    ),
                    // Line 2: Previous Month (Prev)
                    LineChartBarData(
                      spots: List.generate(
                        31,
                        (index) => FlSpot(index.toDouble(), prevList[index]),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYoYTab(bool isDark) {
    // Gather lists of data for selected year and prior 2 years
    final currentList = isTypeAmount
        ? _yoyAmounts[_selectedYear]
        : _yoyLiters[_selectedYear];
    final prev1List = isTypeAmount
        ? _yoyAmounts[_selectedYear - 1]
        : _yoyLiters[_selectedYear - 1];
    final prev2List = isTypeAmount
        ? _yoyAmounts[_selectedYear - 2]
        : _yoyLiters[_selectedYear - 2];

    if (currentList == null || prev1List == null || prev2List == null) {
      return _buildEmptyState("Year-over-Year data could not be computed.");
    }

    if (currentList.every((v) => v == 0) &&
        prev1List.every((v) => v == 0) &&
        prev2List.every((v) => v == 0)) {
      return _buildEmptyState(
        "No sales records available for Yearly comparison.",
      );
    }

    final double maxVal = [
      ...currentList,
      ...prev1List,
      ...prev2List,
    ].reduce((curr, next) => curr > next ? curr : next);

    final double verticalInterval = maxVal > 0 ? (maxVal / 5) : 10.0;
    final String label = isTypeAmount ? "Amount" : "Volume";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? StyleConstants.darkSurface : StyleConstants.lightSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 24, 12),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendIndicator(
                  _selectedYear.toString(),
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 24),
                _buildLegendIndicator(
                  (_selectedYear - 1).toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 24),
                _buildLegendIndicator(
                  (_selectedYear - 2).toString(),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: verticalInterval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _formatAxisValue(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 45,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= 12)
                            return const SizedBox.shrink();
                          // Short month names
                          List<String> shortMonths = [
                            "Jan",
                            "Feb",
                            "Mar",
                            "Apr",
                            "May",
                            "Jun",
                            "Jul",
                            "Aug",
                            "Sep",
                            "Oct",
                            "Nov",
                            "Dec",
                          ];
                          return Text(
                            shortMonths[index],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: maxVal * 1.15,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          int yearLabel = _selectedYear;
                          Color spotColor = const Color(0xFF10B981);
                          if (spot.barIndex == 1) {
                            yearLabel = _selectedYear - 1;
                            spotColor = Colors.blue;
                          } else if (spot.barIndex == 2) {
                            yearLabel = _selectedYear - 2;
                            spotColor = Colors.orange;
                          }

                          final formattedVal = isTypeAmount
                              ? NumberFormat('#,###').format(spot.y)
                              : spot.y.toStringAsFixed(1);
                          final unit = isTypeAmount ? " Ks" : " L";

                          return LineTooltipItem(
                            "$yearLabel - ${_months[spot.x.toInt()]}\n$label: $formattedVal$unit",
                            TextStyle(
                              color: spotColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Line 1: Selected Year
                    LineChartBarData(
                      spots: List.generate(
                        12,
                        (index) => FlSpot(index.toDouble(), currentList[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withOpacity(0.1),
                      ),
                    ),
                    // Line 2: Year - 1
                    LineChartBarData(
                      spots: List.generate(
                        12,
                        (index) => FlSpot(index.toDouble(), prev1List[index]),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Line 3: Year - 2
                    LineChartBarData(
                      spots: List.generate(
                        12,
                        (index) => FlSpot(index.toDouble(), prev2List[index]),
                      ),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllStationsTab(bool isDark) {
    if (isLoadingAllStations && _allStationsData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allStationsData.isEmpty) {
      return _buildEmptyState("No sales records available for any stations.");
    }

    // Find the maximum value to scale progress/share bars
    double maxVal = 0.0;
    for (var data in _allStationsData) {
      double val = _allStationsSortBy == "amount"
          ? data.totalAmount
          : data.totalLiter;
      if (val > maxVal) maxVal = val;
    }

    String sortLabel = _allStationsSortBy == "amount" ? "Amount" : "Volume";
    String orderLabel = _isAllStationsAscending
        ? "Lowest First (အနည်းဆုံးမှ အများဆုံး)"
        : "Highest First (အများဆုံးမှ အနည်းဆုံး)";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? StyleConstants.darkSurface : StyleConstants.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sorting & Controls Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Station Sales Ranking",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Sorting: $sortLabel ($orderLabel)",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sorting controls
                Row(
                  children: [
                    FilterChip(
                      label: const Text(
                        "Amount",
                        style: TextStyle(fontSize: 11),
                      ),
                      selected: _allStationsSortBy == "amount",
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _allStationsSortBy = "amount";
                            _sortAllStationsData();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text(
                        "Volume",
                        style: TextStyle(fontSize: 11),
                      ),
                      selected: _allStationsSortBy == "liter",
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _allStationsSortBy = "liter";
                            _sortAllStationsData();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _isAllStationsAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isDark
                            ? StyleConstants.darkAccent
                            : Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAllStationsAscending = !_isAllStationsAscending;
                          _sortAllStationsData();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            // Station List Table
            Expanded(
              child: ListView.builder(
                itemCount: _allStationsData.length,
                itemBuilder: (context, index) {
                  final data = _allStationsData[index];
                  double val = _allStationsSortBy == "amount"
                      ? data.totalAmount
                      : data.totalLiter;

                  // Calculate percentage share compared to max station sales for the progress bar
                  double shareFraction = maxVal > 0 ? (val / maxVal) : 0.0;

                  // Format value
                  String unit = _allStationsSortBy == "amount" ? " Ks" : " L";
                  String formattedVal = _allStationsSortBy == "amount"
                      ? NumberFormat('#,###').format(val)
                      : val.toStringAsFixed(1);

                  // Rank Badge colors/widgets based on sort order
                  int displayRank = _isAllStationsAscending
                      ? _allStationsData.length - index
                      : index + 1;

                  Widget rankWidget;
                  if (displayRank == 1) {
                    rankWidget = const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFFFD700), // Gold
                      child: Text(
                        "1",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  } else if (displayRank == 2) {
                    rankWidget = const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFC0C0C0), // Silver
                      child: Text(
                        "2",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  } else if (displayRank == 3) {
                    rankWidget = const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFCD7F32), // Bronze
                      child: Text(
                        "3",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  } else {
                    rankWidget = CircleAvatar(
                      radius: 12,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      child: Text(
                        displayRank.toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        rankWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.stationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Relative performance bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: shareFraction,
                                  backgroundColor: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    displayRank == 1
                                        ? const Color(0xFFFFD700)
                                        : (displayRank == 2
                                              ? const Color(0xFFC0C0C0)
                                              : (displayRank == 3
                                                    ? const Color(0xFFCD7F32)
                                                    : (isDark
                                                          ? StyleConstants
                                                                .darkAccent
                                                          : Theme.of(
                                                              context,
                                                            ).primaryColor))),
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "$formattedVal$unit",
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }
}

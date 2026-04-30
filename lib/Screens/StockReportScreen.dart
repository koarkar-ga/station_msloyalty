import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/StockLedgerReport.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _stockData = [];
  bool _isLoading = false;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 0)).copyWith(hour: 0, minute: 0, second: 0);
  DateTime _endDate = DateTime.now().copyWith(hour: 23, minute: 59, second: 59);
  
  List<Map<String, dynamic>> _stations = [];
  String? _selectedStationId;

  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
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
          final allStations = List<Map<String, dynamic>>.from(response);
          if (AppConfig.isHoConfig) {
            _stations = allStations;
            if (AppConfig.currentUserLevel <= 2) {
              _stations.insert(0, {'station_id': 'ALL', 'name': 'ALL STATIONS'});
              _selectedStationId = 'ALL';
            } else {
              _selectedStationId = AppConfig.stationId;
            }
          } else {
            _stations = allStations
                .where((s) => s['station_id'] == AppConfig.stationId)
                .toList();
            if (_stations.isEmpty) {
              _stations = [
                {'station_id': AppConfig.stationId, 'name': AppConfig.stationName}
              ];
            }
            _selectedStationId = AppConfig.stationId;
            // Fetch data automatically
            _fetchStockData();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    }
  }

  Future<void> _fetchStockData() async {
    if (_selectedStationId == null) return;
    
    setState(() {
       _isLoading = true;
       _stockData = [];
    });
    
    // Try DMY format which is common in MS-SQL systems if YMD fails for opening stock
    final startStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(_startDate);
    final endStr = DateFormat('dd-MMM-yyyy HH:mm:ss').format(_endDate);

    try {
      if (_selectedStationId == 'ALL') {
        final targetStations = _stations.where((s) => s['station_id'] != 'ALL').toList();
        List<dynamic> allData = [];
        
        for (var station in targetStations) {
          final sId = station['station_id'];
          final sName = station['name'];
          final url = Uri.parse(
            "${AppConfig.apiUrl}/api/reports/stock-ledger?startDate=$startStr&endDate=$endStr&stationId=$sId"
          );
          
          try {
            final response = await http.get(url, headers: AppConfig.headers);
            if (response.statusCode == 200) {
              final List<dynamic> data = json.decode(response.body);
              for (var row in data) {
                row['station_name'] = sName;
              }
              allData.addAll(data);
            }
          } catch (e) {
            debugPrint("Error fetching for $sName: $e");
          }
        }
        setState(() {
          _stockData = allData;
        });
      } else {
        final url = Uri.parse(
          "${AppConfig.apiUrl}/api/reports/stock-ledger?startDate=$startStr&endDate=$endStr&stationId=$_selectedStationId"
        );
        final response = await http.get(url, headers: AppConfig.headers);
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final sName = _stations.firstWhere((s) => s['station_id'] == _selectedStationId)['name'];
          for (var row in data) {
            row['station_name'] = sName;
          }
          setState(() {
            _stockData = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Stock Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _calculateFuelSummary() {
    Map<String, Map<String, dynamic>> summary = {};
    for (var row in _stockData) {
      String fuel = row['FuelTypeName'] ?? 'Other';
      String code = row['FuelTypeCode'] ?? row['Code'] ?? '-';
      double opening = _getNum(row, 'opening');
      double received = _getNum(row, 'received');
      double sale = _getNum(row, 'sale');
      double closing = _getNum(row, 'closing');
      double actual = _getNum(row, 'tankbalance');

      double adjust = _getNum(row, 'adjust');
      double mobile = _getNum(row, 'mobile');

      if (summary.containsKey(fuel)) {
        summary[fuel]!['opening'] = summary[fuel]!['opening']! + opening;
        summary[fuel]!['received'] = summary[fuel]!['received']! + received;
        summary[fuel]!['sale'] = summary[fuel]!['sale']! + sale;
        summary[fuel]!['adjust'] = summary[fuel]!['adjust']! + adjust;
        summary[fuel]!['mobile'] = summary[fuel]!['mobile']! + mobile;
        summary[fuel]!['closing'] = summary[fuel]!['closing']! + closing;
        summary[fuel]!['actual'] = summary[fuel]!['actual']! + actual;
      } else {
        summary[fuel] = {
          'opening': opening,
          'received': received,
          'sale': sale,
          'adjust': adjust,
          'mobile': mobile,
          'closing': closing,
          'actual': actual,
          'code': double.tryParse(code) ?? 0.0,
          'code_raw': code,
        };
      }
    }
    return summary;
  }

  Widget _buildProductSummaryTable(Map<String, Map<String, dynamic>> summary, bool isDark) {
    final f = NumberFormat('#,###.0');
    final sortedEntries = summary.entries.toList()
      ..sort((a, b) => (a.value['code'] ?? 0).compareTo(b.value['code'] ?? 0));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "PRODUCT SUMMARY",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 35,
              dataRowMaxHeight: 45,
              horizontalMargin: 12,
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(
                isDark ? Colors.teal.withOpacity(0.2) : Colors.teal.withOpacity(0.05),
              ),
              columns: const [
                DataColumn(label: Text("#", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Code", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Item Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Opening", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                DataColumn(label: Text("Receipt", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                DataColumn(label: Text("Sale", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                DataColumn(label: Text("System Bal", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                DataColumn(label: Text("Tank Actual", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                DataColumn(label: Text("Today G/L", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
              rows: List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final fuel = entry.key;
                final v = entry.value;
                final gl = v['actual']! - v['closing']!;
                
                return DataRow(
                  cells: [
                    DataCell(Text("${index + 1}", style: const TextStyle(fontSize: 11))),
                    DataCell(Text(v['code_raw']?.toString() ?? "-", style: const TextStyle(fontSize: 11))),
                    DataCell(Text(fuel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                    DataCell(Text(f.format(v['opening']), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(f.format(v['received']), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(f.format(v['sale']), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(f.format(v['closing']), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text(f.format(v['actual']), style: const TextStyle(fontSize: 11, color: Colors.blue))),
                    DataCell(
                      Text(
                        f.format(gl),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: gl < 0 ? Colors.red : (gl > 0 ? Colors.green : null),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fuelSummary = _calculateFuelSummary();
    
    return Scaffold(
      appBar: MsAppBar(
        title: "Stock Report",
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _stockData.isEmpty ? null : () => exportStockLedgerReport(_stockData),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(isDark),
                if (_stockData.isNotEmpty) ...[
                  _buildProductSummaryTable(fuelSummary, isDark),
                  _buildSummaryCards(fuelSummary, isDark),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Tank Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildTankStatus(isDark),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Stock Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _stockData.isEmpty 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text("Please select filters and click GET"),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return _buildDataTable(isDark);
                        } else {
                          return _buildMobileStockList(isDark);
                        }
                      },
                    ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildTankStatus(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _stockData.map((tank) {
          final capacity = (tank['Capacity'] ?? 0).toDouble();
          final balance = (tank['tankbalance'] ?? 0).toDouble();
          final percent = capacity > 0 ? (balance / capacity).clamp(0.0, 1.0) : 0.0;
          
          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                 if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tank['Tank_Name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(tank['FuelTypeName'] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent < 0.2 ? Colors.red : (percent > 0.8 ? Colors.orange : Colors.green)
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(percent * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text("Actual: ${NumberFormat('#,###').format(balance)}", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, Map<String, dynamic>> summary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: summary.entries.map((e) => _buildFuelCard(e.key, e.value, isDark)).toList(),
      ),
    );
  }

  Widget _buildFuelCard(String fuel, Map<String, dynamic> values, bool isDark) {
    final f = NumberFormat('#,###.0');
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fuel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
          const SizedBox(height: 8),
          _row("Opening", f.format(values['opening'])),
          _row("Received (L)", f.format(values['received'])),
          _row("Received (G)", f.format(values['received']! / 4.546)),
          _row("Total Sale", f.format(values['sale'])),
          if (values['adjust'] != 0) _row("Adjust", f.format(values['adjust'])),
          if (values['mobile'] != 0) _row("Mobile", f.format(values['mobile'])),
          _row("Tank Actual", f.format(values['actual'])),
          const Divider(),
          _row("System Balance", f.format(values['closing'])),
          _row("Today G/L", f.format(values['actual']! - values['closing']!), 
               color: (values['actual']! - values['closing']!) < 0 ? Colors.red : Colors.green),
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(val, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.white10 : Colors.blueGrey.shade50,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Station Selection (only for Admin and HO)
          if (AppConfig.isHoConfig && AppConfig.currentUserLevel <= 2)
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedStationId,
                decoration: const InputDecoration(labelText: "Station", isDense: true),
                items: _stations.map((s) => DropdownMenuItem(
                  value: s['station_id'].toString(),
                  child: Text(s['name']),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedStationId = val);
                },
              ),
            ),
          
          // Start Date Time
          InkWell(
            onTap: () async {
              final picked = await _selectDateTime(context, _startDate);
              if (picked != null) setState(() => _startDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 8),
                  Text("Start: ${DateFormat('dd/MM/yy HH:mm').format(_startDate)}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),

          // End Date Time
          InkWell(
            onTap: () async {
              final picked = await _selectDateTime(context, _endDate);
              if (picked != null) setState(() => _endDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 8),
                  Text("End: ${DateFormat('dd/MM/yy HH:mm').format(_endDate)}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),

          // GET Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchStockData,
            icon: const Icon(Icons.search),
            label: const Text("GET"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(bool isDark) {
    final showStation = _selectedStationId == 'ALL';
    // Table content width is fixed to 2200 to ensure horizontal scrolling is needed
    const double tableWidth = 2200;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        thickness: 8.0,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Container(
            width: tableWidth,
            padding: const EdgeInsets.only(bottom: 24),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.1)),
              columnSpacing: 20,
              horizontalMargin: 12,
              columns: [
                if (showStation) const DataColumn(label: Text("Station")),
                const DataColumn(label: Text("Tank")),
                const DataColumn(label: Text("Fuel")),
                const DataColumn(label: Text("Opening")),
                const DataColumn(label: Text("Receive (L)")),
                const DataColumn(label: Text("Receive (G)")),
                const DataColumn(label: Text("Cash Sale")),
                const DataColumn(label: Text("Credit")),
                const DataColumn(label: Text("FOC")),
                const DataColumn(label: Text("Transfer")),
                const DataColumn(label: Text("IU Offline")),
                const DataColumn(label: Text("Adv Sale")),
                const DataColumn(label: Text("Zone Sale")),
                const DataColumn(label: Text("ePayment")),
                const DataColumn(label: Text("Operate")),
                const DataColumn(label: Text("Total Sale")),
                const DataColumn(label: Text("Adjust")),
                const DataColumn(label: Text("Mobile")),
                const DataColumn(label: Text("Balance")),
                const DataColumn(label: Text("Actual")),
                const DataColumn(label: Text("Today GL")),
              ],
              rows: _stockData.map((row) {
                return DataRow(
                  cells: [
                    if (showStation) DataCell(Text(row['station_name']?.toString() ?? '-')),
                    DataCell(Text(row['Tank_Name']?.toString() ?? '-')),
                    DataCell(Text(row['FuelTypeName']?.toString() ?? '-')),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'opening')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'received')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'received') / 4.546))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'cash_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'credit_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'foc_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'tran_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'iu_offline')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'adv_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'zone_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'epay_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'operate_sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'sale')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'adjust')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'mobile')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'closing')))),
                    DataCell(Text(NumberFormat('#,###.0').format(_getNum(row, 'tankbalance')))),
                    DataCell(
                      Text(
                        NumberFormat('#,###.0').format(_getNum(row, 'Gain_Mine')),
                        style: TextStyle(
                          color: (_getNum(row, 'Gain_Mine')) >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStockList(bool isDark) {
    final showStation = _selectedStationId == 'ALL';
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stockData.length,
      itemBuilder: (context, index) {
        final row = _stockData[index];
        final f = NumberFormat('#,###.##');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(row['Tank_Name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${row['FuelTypeName']} - Actual: ${f.format(row['tankbalance'])}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (showStation) _cardRow("Station", row['station_name']?.toString() ?? '-'),
                    _cardRow("Opening", f.format(row['opening'] ?? 0)),
                    _cardRow("Receive", f.format(row['received'] ?? 0)),
                    _cardRow("Cash Sale", f.format(row['cash_sale'] ?? 0)),
                    _cardRow("Credit", f.format(row['credit_sale'] ?? 0)),
                    _cardRow("FOC", f.format(row['foc_sale'] ?? 0)),
                    _cardRow("Transfer", f.format(row['tran_sale'] ?? 0)),
                    _cardRow("Total Sale", f.format(row['sale'] ?? 0)),
                    _cardRow("Balance", f.format(row['closing'] ?? 0)),
                    _cardRow("Tank Actual", f.format(row['tankbalance'] ?? 0), isBold: true, color: Colors.blue),
                    _cardRow(
                      "Gain/Loss", 
                      f.format(row['Gain_Mine'] ?? 0), 
                      isBold: true, 
                      color: (row['Gain_Mine'] ?? 0) >= 0 ? Colors.green : Colors.red
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _cardRow(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            val, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: 12,
             )
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _selectDateTime(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    if (!context.mounted) return date;

    // Show time picker immediately after date selection
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    
    if (time == null) {
      // If time selection is cancelled, use original time from 'initial' or 00:00/23:59 based on intention
      return DateTime(date.year, date.month, date.day, initial.hour, initial.minute);
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  double _getNum(dynamic row, String key) {
    if (row == null) return 0.0;
    
    // 1. Try to find the value using various key formats
    dynamic val = row[key];
    
    // 2. Specialized fallbacks for "opening" which is often named differently
    if (val == null && key.toLowerCase() == 'opening') {
      val = row['opening_balance'] ?? 
            row['Opening_Balance'] ?? 
            row['OpeningBalance'] ?? 
            row['opening_stock'] ?? 
            row['OpeningStock'] ??
            row['stock_opening'] ??
            row['Balance_Opening'];
    }

    // 3. General fallbacks (CamelCase, PascalCase, UPPERCASE)
    if (val == null) {
      val = row[key.substring(0, 1).toUpperCase() + key.substring(1)] ?? 
            row[key.toUpperCase()];
    }
    
    if (val == null) return 0.0;

    if (val is num) return val.toDouble();
    
    // 4. Handle String numbers (remove commas)
    final cleaned = val.toString().replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

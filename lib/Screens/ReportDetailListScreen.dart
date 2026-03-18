import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Model/BuildFuelTypeChip.dart';
import 'package:station_msloyalty/Model/SaleTypeModel.dart';
import 'package:station_msloyalty/Screens/CheckAlreadyCollectedReport.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDetailListScreen extends StatefulWidget {
  final List<dynamic> salesData;
  final SupabaseClient supabase;

  const ReportDetailListScreen({
    super.key,
    required this.salesData,
    required this.supabase,
  });

  @override
  State<ReportDetailListScreen> createState() => _ReportDetailListScreenState();
}

class _ReportDetailListScreenState extends State<ReportDetailListScreen> {
  late List<dynamic> _filteredData;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFuelType = 'All';
  String _sortBy = 'Time'; // 'Time', 'Liter', 'Amount'
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.salesData);
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredData = widget.salesData.where((sale) {
        final vocNo = sale['VocNo'].toString().toLowerCase();
        final searchText = _searchController.text.toLowerCase();
        final matchesSearch = vocNo.contains(searchText);

        final fuelType = sale['FuelTypeName'] ?? '';
        final matchesFuel =
            _selectedFuelType == 'All' || fuelType == _selectedFuelType;

        return matchesSearch && matchesFuel;
      }).toList();

      // Apply Sorting
      _filteredData.sort((a, b) {
        int comparison = 0;
        if (_sortBy == 'Time') {
          final dateA = DateTime.parse(a['S_Date']);
          final dateB = DateTime.parse(b['S_Date']);
          comparison = dateA.compareTo(dateB);
        } else if (_sortBy == 'Liter') {
          final literA = double.tryParse(a['SALELITER'].toString()) ?? 0;
          final literB = double.tryParse(b['SALELITER'].toString()) ?? 0;
          comparison = literA.compareTo(literB);
        } else if (_sortBy == 'Amount') {
          final amountA = double.tryParse(a['TotalPrice'].toString()) ?? 0;
          final amountB = double.tryParse(b['TotalPrice'].toString()) ?? 0;
          comparison = amountA.compareTo(amountB);
        }
        return _isAscending ? comparison : -comparison;
      });
    });
  }

  List<String> _getFuelTypes() {
    final types = widget.salesData
        .map((e) => (e['FuelTypeName'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    types.sort();
    return ['All', ...types];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fuelTypes = _getFuelTypes();

    return Scaffold(
      backgroundColor: isDark ? StyleConstants.darkBg : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Report Details"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _applyFilters();
              });
            },
            icon: Icon(_isAscending ? Icons.south : Icons.north, size: 20),
            tooltip: "Toggle Sort Order",
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Time', child: Text('Sort by Time')),
              const PopupMenuItem(value: 'Liter', child: Text('Sort by Liter')),
              const PopupMenuItem(
                value: 'Amount',
                child: Text('Sort by Amount'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: isDark ? StyleConstants.darkSurface : Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: "Search Voucher No...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fuelTypes.length,
                    itemBuilder: (context, index) {
                      final type = fuelTypes[index];
                      final isSelected = _selectedFuelType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFuelType = type;
                              _applyFilters();
                            });
                          },
                          selectedColor: getFuelColor(type).withOpacity(0.2),
                          checkmarkColor: getFuelColor(type),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.teal
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.teal
                                : Colors.transparent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Result Status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  "Showing ${_filteredData.length} records",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Spacer(),
                if (_sortBy != 'Time')
                  Text(
                    "Sorted by $_sortBy",
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          // Data List
          Expanded(
            child: _filteredData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final sale = _filteredData[index];
                      return _buildMobileReportCard(sale, index, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReportCard(dynamic sale, int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        opacity: isDark ? 0.05 : 0.02,
        borderRadius: 16,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#${index + 1}",
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildStatusBadge(sale['Sale_Type_name']),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            _cardRow(
              Icons.receipt_outlined,
              "Voucher",
              sale['VocNo']?.toString() ?? '-',
            ),
            _cardRow(
              Icons.local_gas_station_outlined,
              "Fuel Grade",
              sale['FuelTypeName']?.toString() ?? '-',
            ),
            _cardRow(
              Icons.directions_car_outlined,
              "Vehicle",
              sale['Vehical_No']?.toString() ?? '-',
            ),
            _cardRow(Icons.access_time, "Time", _formatDate(sale['S_Date'])),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AMOUNT",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${NumberFormat('#,###').format(sale['TotalPrice'] ?? 0)} Ks",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "LITERS",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${sale['SALELITER']?.toString() ?? '0.00'} L",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child:
                  (sale['Sale_Type_name'] == 'Cash Sale' ||
                      sale['Sale_Type_name'] == 'ePayment')
                  ? CheckAlreadyCollectedReport(
                      sale: sale,
                      supabase: widget.supabase,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Non-Cash Sale - No Action Needed",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? type) {
    final color = getSaleTypeColor(type ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type ?? '-',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm aa').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No results found",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try adjusting your search or filters",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

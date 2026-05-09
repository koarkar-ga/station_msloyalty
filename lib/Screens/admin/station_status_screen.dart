import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/AppConfig.dart';

class StationStatusScreen extends StatefulWidget {
  const StationStatusScreen({Key? key}) : super(key: key);

  @override
  State<StationStatusScreen> createState() => _StationStatusScreenState();
}

class _StationStatusScreenState extends State<StationStatusScreen> {
  late Future<List<StationInfo>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchStationStatus();
  }

  Future<List<StationInfo>> _fetchStationStatus() async {
    // 1. Fetch ALL stations from Supabase (source of truth)
    final stationsResponse = await Supabase.instance.client
        .from('stations')
        .select('station_id, name')
        .order('station_id');

    if (stationsResponse == null || (stationsResponse as List).isEmpty) {
      return [];
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // Base API URL — same as ReportScreen
    final String baseApiUrl = AppConfig.apiUrl;

    // 2. Fetch all stations in PARALLEL — same pattern as ReportScreen
    final futures = (stationsResponse as List).map((station) async {
      final String stationCode = station['station_id']?.toString() ?? '';
      final String stationName = station['name']?.toString() ?? stationCode;

      if (stationCode.isEmpty) {
        return null;
      }

      DateTime? lastSale;
      LastTransaction? lastTx;
      String errorMsg = '';

      try {
        // Build URL exactly like ReportScreen._fetchLatestSales does:
        // '$apiUrl?stationId=$sId' where apiUrl = "${AppConfig.apiUrl}/api/sales/recent"
        final String url =
            '$baseApiUrl/api/sales/recent?stationId=$stationCode';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'x-station-id': stationCode,
          },
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final first = data.first;

            // Parse S_Date — same logic as ReportScreen._parseServerDateTime
            final String? rawDate = first['S_Date']?.toString();
            if (rawDate != null && rawDate.isNotEmpty) {
              try {
                String normalized = rawDate;
                if (normalized.contains(' ') && !normalized.contains('T')) {
                  normalized = normalized.replaceFirst(' ', 'T');
                }
                lastSale = DateTime.parse(normalized);
              } catch (_) {}
            }

            lastTx = LastTransaction(
              vocNo: first['VocNo']?.toString() ?? '-',
              sDate: lastSale,
              fuelType: first['FuelTypeName']?.toString() ?? '-',
              saleLiter: _toDouble(first['SALELITER']),
              totalPrice: _toDouble(first['TotalPrice']),
              saleType: first['Sale_Type_name']?.toString() ?? '-',
            );
          }
        } else {
          errorMsg = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        // Show a shorter error message with the base URL for debugging
        final host = Uri.tryParse(baseApiUrl)?.host ?? baseApiUrl;
        errorMsg = 'Unreachable ($host)';
      }

      // Online = last sale date is today
      bool online = false;
      if (lastSale != null) {
        final lastDate =
            DateTime(lastSale.year, lastSale.month, lastSale.day);
        online = lastDate == todayDate;
      }

      return StationInfo(
        id: stationCode,
        name: stationName,
        latest: lastSale,
        online: online,
        error: errorMsg,
        lastTx: lastTx,
      );
    }).toList();

    // Await all in parallel
    final rawResults = await Future.wait(futures);
    final results = rawResults
        .whereType<StationInfo>()
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return results;
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0.0;

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd-MMM-yyyy  hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Station Online Status'),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {
              _futureData = _fetchStationStatus();
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<StationInfo>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Checking station connections...',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('No station data available.'));
          }

          final onlineCount = data.where((s) => s.online).length;
          final offlineCount = data
              .where((s) => !s.online && s.error.isEmpty)
              .length;
          final errorCount = data.where((s) => s.error.isNotEmpty).length;

          return Column(
            children: [
              // ── Summary bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _chip('Total', data.length, Colors.blueGrey, isDark),
                    _chip('Online', onlineCount, Colors.green, isDark),
                    _chip('Offline', offlineCount, Colors.red, isDark),
                    if (errorCount > 0)
                      _chip('Error', errorCount, Colors.orange, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Station list ──
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildStationCard(data[index], isDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Station Card ────────────────────────────────────────────────────────
  Widget _buildStationCard(StationInfo item, bool isDark) {
    final statusColor = item.error.isNotEmpty
        ? Colors.orange
        : item.online
            ? Colors.green
            : Colors.red;
    final statusLabel = item.error.isNotEmpty
        ? 'Error'
        : item.online
            ? 'Online'
            : 'Offline';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.45),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.id,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.blueGrey[300]
                        : Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color:
                (isDark ? Colors.white : Colors.black).withOpacity(0.07),
          ),

          // ── Last Transaction ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: item.error.isNotEmpty
                ? Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      item.error,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ])
                : item.lastTx == null
                    ? Text(
                        'No sale transaction found',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.blueGrey[400]
                              : Colors.blueGrey[400],
                        ),
                      )
                    : _buildTransactionRow(item.lastTx!, isDark),
          ),
        ],
      ),
    );
  }

  // ── Transaction Detail Row ──────────────────────────────────────────────
  Widget _buildTransactionRow(LastTransaction tx, bool isDark) {
    final fmt = NumberFormat('#,###');
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _txField(Icons.access_time_rounded, 'Date & Time',
            tx.sDate != null ? _formatDateTime(tx.sDate!) : '-', isDark),
        _txField(Icons.receipt_long_rounded, 'Voucher No', tx.vocNo, isDark),
        _txField(Icons.local_gas_station_rounded, 'Fuel Type', tx.fuelType,
            isDark,
            accent: _fuelColor(tx.fuelType)),
        _txField(Icons.opacity_rounded, 'Liter',
            '${tx.saleLiter.toStringAsFixed(2)} L', isDark),
        _txField(Icons.payments_rounded, 'Amount',
            '${fmt.format(tx.totalPrice)} Ks', isDark,
            accent: Colors.teal),
        _txField(Icons.category_rounded, 'Sale Type', tx.saleType, isDark),
      ],
    );
  }

  Widget _txField(IconData icon, String label, String value, bool isDark,
      {Color? accent}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: accent ??
                (isDark ? Colors.blueGrey[400] : Colors.blueGrey[400])),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? Colors.blueGrey[500]
                      : Colors.blueGrey[400],
                )),
            Text(value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent ?? (isDark ? Colors.white : Colors.black87),
                )),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, int count, Color color, bool isDark) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
            )),
      ],
    );
  }

  Color _fuelColor(String fuelType) {
    final f = fuelType.toLowerCase();
    if (f.contains('92')) return Colors.blue;
    if (f.contains('95')) return Colors.indigo;
    if (f.contains('premium')) return Colors.purple;
    if (f.contains('diesel')) return Colors.brown;
    return Colors.blueGrey;
  }
}

// ── Models ──────────────────────────────────────────────────────────────────

class LastTransaction {
  final String vocNo;
  final DateTime? sDate;
  final String fuelType;
  final double saleLiter;
  final double totalPrice;
  final String saleType;

  LastTransaction({
    required this.vocNo,
    this.sDate,
    required this.fuelType,
    required this.saleLiter,
    required this.totalPrice,
    required this.saleType,
  });
}

class StationInfo {
  final String id;
  final String name;
  final DateTime? latest;
  final bool online;
  final String error;
  final LastTransaction? lastTx;

  StationInfo({
    required this.id,
    required this.name,
    this.latest,
    required this.online,
    this.error = '',
    this.lastTx,
  });
}

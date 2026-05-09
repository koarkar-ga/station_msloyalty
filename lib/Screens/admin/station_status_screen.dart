import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:bot_toast/bot_toast.dart';

class StationStatusScreen extends StatefulWidget {
  const StationStatusScreen({Key? key}) : super(key: key);

  @override
  State<StationStatusScreen> createState() => _StationStatusScreenState();
}

class _StationStatusScreenState extends State<StationStatusScreen> {
  List<StationInfo> _results = [];
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  int _processedCount = 0;

  @override
  void initState() {
    super.initState();
    _startFetching();
  }

  Future<void> _startFetching() async {
    setState(() {
      _isRefreshing = true;
      _results = [];
      _processedCount = 0;
    });
    await _fetchStationStatus();
    setState(() {
      _isRefreshing = false;
      _isInitialLoading = false;
    });
  }

  Future<void> _fetchStationStatus() async {
    try {
      // 1. Fetch ALL stations from Supabase (source of truth)
      final stationsResponse = await Supabase.instance.client
          .from('stations')
          .select('station_id, name')
          .order('station_id');

      if (stationsResponse == null || (stationsResponse as List).isEmpty) {
        return;
      }

      final List stations = stationsResponse as List;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final String baseApiUrl = AppConfig.apiUrl;

      // Initialize results with "Processing" state
      final List<StationInfo> initialResults = stations.map((s) {
        return StationInfo(
          id: s['station_id']?.toString() ?? '',
          name: s['name']?.toString() ?? '',
          online: false,
          isProcessing: true,
        );
      }).toList();

      setState(() {
        _results = initialResults;
        _isInitialLoading = false;
      });

      // 2. Fetch each station sequentially
      for (int i = 0; i < _results.length; i++) {
        final stationCode = _results[i].id;
        if (stationCode.isEmpty) continue;

        DateTime? lastSale;
        LastTransaction? lastTx;
        String errorMsg = '';
        final String url =
            '$baseApiUrl/api/sales/lastsale?stationId=$stationCode';

        try {
          final response = await http
              .get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'x-station-id': stationCode,
                },
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final dynamic data = json.decode(response.body);
            if (data != null && data is Map<String, dynamic>) {
              final first = data;
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
          final host = Uri.tryParse(baseApiUrl)?.host ?? baseApiUrl;
          errorMsg = 'Unreachable ($host)';
        }

        bool online = false;
        if (lastSale != null) {
          final lastDate = DateTime(
            lastSale.year,
            lastSale.month,
            lastSale.day,
          );
          online = lastDate == todayDate;
        }

        setState(() {
          _results[i] = StationInfo(
            id: _results[i].id,
            name: _results[i].name,
            latest: lastSale,
            online: online,
            error: errorMsg,
            apiUrl: url,
            lastTx: lastTx,
            isProcessing: false,
          );
          _processedCount++;
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0.0;

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd-MMM-yyyy  hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onlineStations = _results
        .where((s) => s.online && !s.isProcessing)
        .toList();
    final offlineStations = _results
        .where((s) => !s.online && !s.isProcessing)
        .toList();
    final processingStations = _results.where((s) => s.isProcessing).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.blueGrey[50],
        appBar: AppBar(
          title: const Text('Station Online Status'),
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: isDark ? Colors.white : Colors.black87,
            tabs: [
              Tab(text: 'All Station (${_results.length})'),
              Tab(text: 'Online Station (${onlineStations.length})'),
              Tab(text: 'Offline Station (${offlineStations.length})'),
            ],
          ),
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSummaryBar(isDark),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStationList(_results, isDark),
                        _buildStationList(onlineStations, isDark),
                        _buildStationList(offlineStations, isDark),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isRefreshing ? null : _startFetching,
          backgroundColor: Colors.blueAccent,
          child: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildStationList(List<StationInfo> stations, bool isDark) {
    if (stations.isEmpty && !_isRefreshing) {
      return const Center(child: Text('No stations found in this category.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _buildStationCard(stations[index], isDark),
    );
  }

  Widget _buildSummaryBar(bool isDark) {
    int total = _results.length;
    int online = _results.where((s) => s.online && !s.isProcessing).length;
    int offline = _results.where((s) => !s.online && !s.isProcessing).length;
    int processing = _results.where((s) => s.isProcessing).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chip('Total', total, Colors.blueGrey, isDark),
              _chip('Online', online, Colors.green, isDark),
              _chip('Offline', offline, Colors.red, isDark),
            ],
          ),
          if (processing > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total > 0 ? _processedCount / total : 0,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.blueAccent,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Checking $_processedCount of $total stations...',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.blueGrey[400] : Colors.blueGrey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Station Card ────────────────────────────────────────────────────────
  Widget _buildStationCard(StationInfo item, bool isDark) {
    final statusColor = item.online ? Colors.green : Colors.red;
    final lastTime = item.latest != null
        ? _formatDateTime(item.latest!)
        : 'No transaction';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Station ID & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.id} - ${item.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.error.isNotEmpty)
                  Text(
                    item.error,
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
              ],
            ),
          ),
          // Time or Processing Spinner
          if (item.isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            )
          else
            Text(
              lastTime,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[600],
          ),
        ),
      ],
    );
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
  final String? apiUrl;
  final LastTransaction? lastTx;
  final bool isProcessing;

  StationInfo({
    required this.id,
    required this.name,
    this.latest,
    required this.online,
    this.error = '',
    this.apiUrl,
    this.lastTx,
    this.isProcessing = false,
  });
}

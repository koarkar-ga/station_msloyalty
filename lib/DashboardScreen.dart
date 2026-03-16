import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/BuildLoadingTile.dart';
import 'package:station_msloyalty/Helper/BuildRedemptionHistory.dart';
import 'package:station_msloyalty/Helper/BuildSummaryGrid.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = Future.wait([
      getSummaryData(),
      getPointsSummary(),
      getIssuedPointsSummary(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const MsAppBar(title: 'Station Dashboard', showBackButton: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [StyleConstants.darkBg, const Color(0xFF1E293B)]
              : [StyleConstants.lightBg, const Color(0xFFE2E8F0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${AppConfig.stationName}",
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : StyleConstants.lightText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "OVERVIEW",
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white70 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ၁။ အပေါ်က Statistics Cards များ
              FutureBuilder<List<dynamic>>(
                future: _statsFuture,
                builder: (context, asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return buildLoadingTile("Loading Statistics...");
                  }
                  
                  final pointsData = asyncSnapshot.data?[1] ?? [];
                  final issuedPointsData = asyncSnapshot.data?[2] ?? [];
                  
                  final totalRewards = pointsData.isNotEmpty ? (pointsData[0]['total_points'] ?? 0) : 0;
                  final pointsIssued = issuedPointsData.isNotEmpty ? (issuedPointsData[0]['total_points'] ?? 0) : 0;

                  return Row(
                    children: [
                      _buildGlassStatCard(
                        "TOTAL REWARDS",
                        "${formatter.format(totalRewards)}",
                        "PTS",
                        Icons.card_giftcard,
                        Colors.orangeAccent,
                        context,
                      ),
                      const SizedBox(width: 20),
                      _buildGlassStatCard(
                        "POINTS ISSUED",
                        "${formatter.format(pointsIssued)}",
                        "PTS",
                        Icons.stars,
                        Colors.greenAccent,
                        context,
                      ),
                      const SizedBox(width: 10),
                      _buildGlassStatCard(
                        "STATION NAME",
                        AppConfig.stationName,
                        "",
                        Icons.location_city,
                        Colors.blueAccent,
                        context,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // ၂။ အောက်က Main Content (Charts နှင့် Recent List)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ဘယ်ဘက်ခြမ်း - Summary/Charts နေရာ
                    Expanded(
                      flex: 2, 
                      child: GlassContainer(
                        padding: const EdgeInsets.all(2),
                        child: const SummaryGridWidget(),
                      )
                    ),
                    const SizedBox(width: 24),

                    // ညာဘက်ခြမ်း - Recent Redemptions
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                            child: Text(
                              "RECENT REDEMPTIONS",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GlassContainer(
                              child: const RedemptionHistoryList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Statistics Card Builder with Glassmorphism
  Widget _buildGlassStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.trending_up, color: color.withOpacity(0.3), size: 18),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : StyleConstants.lightText,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45, 
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> getSummaryData() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    
    final url = Uri.parse('${AppConfig.apiUrl}/api/summary/data')
        .replace(queryParameters: {
          'stationId': AppConfig.stationId,
          'date': todayStart,
        });
        
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load summary data ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getPointsSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    try {
      final response = await Supabase.instance.client.rpc(
        'get_points_summary_by_station',
        params: {
          'start_date': todayStart,
          'p_station_id': AppConfig.stationId,
        },
      );
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('RPC Error: $e');
      return [
        {'station_id': 'Error', 'total_points': 0},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getIssuedPointsSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    try {
      final response = await Supabase.instance.client.rpc(
        'get_issued_points_summary_by_station',
        params: {
          'start_date': todayStart,
          'p_station_id': AppConfig.stationId,
        },
      );
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('RPC Error: $e');
      return [
        {'station_id': 'Error', 'total_points': 0},
      ];
    }
  }
}

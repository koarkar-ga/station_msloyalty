import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/BuildLoadingTile.dart';
import 'package:station_msloyalty/Model/BuildFuelTypeChip.dart';
import 'package:station_msloyalty/Model/SaleTypeModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SummaryGridWidget extends StatefulWidget {
  const SummaryGridWidget({super.key});

  @override
  State<SummaryGridWidget> createState() => _SummaryGridWidgetState();
}

class _SummaryGridWidgetState extends State<SummaryGridWidget> {
  late Future<List<PieChartSectionData>> _redemptionFuture;
  late Future<List<PieChartSectionData>> _rewardPointFuture;

  @override
  void initState() {
    super.initState();
    _redemptionFuture = _getRedemptionData();
    _rewardPointFuture = _getRewardPointData();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      padding: const EdgeInsets.all(20),
      children: [
        // ၁။ Sale Type Summary (From Node.js API)
        // _buildFutureChart("Sale Type Summary", _getSaleTypeData()),

        // ၂။ Fuel Sale Summary (From Node.js API)
        // _buildFutureChart("Fuel Sale Summary", _getFuelSaleData()),

        // ၄။ Redemption Summary (From Supabase)
        _buildFutureChart("Redemption Summary", _redemptionFuture, context),

        // ၃။ Point Reward Summary (From Supabase)
        _buildFutureChart("Point Reward Summary", _rewardPointFuture, context),
      ],
    );
  }
}

Widget _buildFutureChart(
  String title,
  Future<List<PieChartSectionData>> futureData,
  BuildContext context,
) {
  return FutureBuilder<List<PieChartSectionData>>(
    future: futureData,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return buildLoadingTile(title); // Data စောင့်နေတုန်း
      } else if (snapshot.hasError) {
        return _buildErrorTile(
          title,
          snapshot.error.toString(),
          context,
        ); // Error တက်ရင်
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildEmptyTile(title, context); // Data မရှိရင်
      }

      // Data ရပြီဆိုမှ ငါတို့ အစောကလုပ်ထားတဲ့ Pie Chart Widget ကို ခေါ်မယ်
      return _buildPieChartTile(title, snapshot.data!, context);
    },
  );
}

Widget _buildErrorTile(String title, String errorMessage, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: isDark ? Colors.white12 : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.red.shade50),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 30),
              const SizedBox(height: 8),
              Text(
                "Connection Error",
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyTile(String title, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: isDark ? Colors.white12 : Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey[300], size: 35),
              const SizedBox(height: 10),
              Text(
                "No Data Found",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                "Records will appear here once transactions start.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPieChartTile(String title, List<PieChartSectionData> sections, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: isDark ? Colors.white12 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              // Pie Chart အပိုင်း
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(enabled: false), // Disable hover effects to prevent mouse tracker crash
                    sections: sections,
                    centerSpaceRadius: 30, // အလယ်က အပေါက်
                    sectionsSpace: 2,
                  ),
                ),
              ),
              // Detail Amount (Legend) အပိုင်း
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections
                      .map((data) => _buildLegendItem(data, context))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildLegendItem(PieChartSectionData data, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        const SizedBox(width: 20),
        Container(width: 10, height: 10, color: data.color),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            "${data.title}: ${data.value.toInt()}",
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// Redemption Summary အတွက် ဥပမာ (Supabase ကနေ count လုပ်ပြီး ယူနိုင်သည်)
Future<List<PieChartSectionData>> _getRedemptionData() async {
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    // gift_cards table နဲ့ join ပြီး title တွေပါ တစ်ခါတည်း ယူနိုင်တယ်
    final response = await Supabase.instance.client
        .from('redemption_history')
        .select('points_spent, gift_cards(title)')
        .eq('station_id', AppConfig.stationId) // Filter by station
        .gte('created_at', todayStart); // Filter by today

    Map<String, double> summary = {};
    for (var item in response) {
      String title = item['gift_cards']['title'] ?? 'Unknown';
      summary[title] = (summary[title] ?? 0) + 1;
    }

    int index = 0;
    return summary.entries.map((entry) {
      index++;
      return PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: Colors.primaries[index % Colors.primaries.length],
        radius: 50,
        showTitle: false,
      );
    }).toList();
  } catch (e) {
    print("Reward Summary Error: $e");
    return [];
  }
}

// ၁။ Sale Type Summary Data (Node.js API)
Future<List<PieChartSectionData>> _getSaleTypeData() async {
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    final url = Uri.parse('${AppConfig.apiUrl}/api/summary/saletypes').replace(
      queryParameters: {'stationId': AppConfig.stationId, 'date': todayStart},
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        return PieChartSectionData(
          value: item['value'].toDouble(),
          title: item['label'],
          color: getSaleTypeColor(item['label']),
          radius: 50,
          showTitle: false,
        );
      }).toList();
    }
    return [];
  } catch (e) {
    print("Sale Type Summary Error: $e");
    return [];
  }
}

// ၂။ Fuel Sale Summary Data (Node.js API)
Future<List<PieChartSectionData>> _getFuelSaleData() async {
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    final url = Uri.parse('${AppConfig.apiUrl}/api/summary/fuelsales').replace(
      queryParameters: {'stationId': AppConfig.stationId, 'date': todayStart},
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        return PieChartSectionData(
          value: item['value'].toDouble(),
          title: item['label'],
          color: getFuelColor(item['label']), // အစောက ရေးထားတဲ့ helper function
          radius: 50,
          showTitle: false,
        );
      }).toList();
    }
    return [];
  } catch (e) {
    print("Fuel Sale Summary Error: $e");
    return [];
  }
}

// ၃။ Reward Point Summary (Supabase)
Future<List<PieChartSectionData>> _getRewardPointData() async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

  final response = await Supabase.instance.client
      .from('fuel_transactions')
      .select('points_earned, fuel_type')
      .eq('station_id', AppConfig.stationId) // Filter by station
      .gte('created_at', todayStart);

  if ((response as List).isEmpty) {
    return [];
  }

  final List data = response as List;

  // ဆီအမျိုးအစားအလိုက် point တွေကို ပေါင်းဖို့ Map တစ်ခုဆောက်မယ်
  Map<String, double> fuelPointsMap = {};

  for (var item in data) {
    String fuelType = item['fuel_type'] ?? 'Unknown';
    double points = (item['points_earned'] ?? 0).toDouble();

    // ရှိပြီးသား fuel type ဆိုရင် point ထပ်ပေါင်းမယ်၊ မရှိရင် အသစ်ထည့်မယ်
    fuelPointsMap[fuelType] = (fuelPointsMap[fuelType] ?? 0) + points;
  }

  // ပေါင်းရလာတဲ့ Map ကို PieChartSectionData list အဖြစ်ပြောင်းမယ်
  return fuelPointsMap.entries.map((entry) {
    return PieChartSectionData(
      value: entry
          .value, // ဒီမှာ count မဟုတ်တော့ဘဲ point amount စုစုပေါင်း ဖြစ်သွားပြီ
      title: entry.key,
      radius: 50,
      showTitle: false,
      color: getFuelColor(entry.key), // ဆီအရောင်နဲ့ ချိတ်မယ်
    );
  }).toList();
}

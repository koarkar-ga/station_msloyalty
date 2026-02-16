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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MsAppBar()),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppConfig.stationName} Station Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ၁။ အပေါ်က Statistics Cards များ
            FutureBuilder<List<dynamic>>(
              future: Future.wait([getSummaryData(), getPointsSummary(), getIssuedPointsSummary()]),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return Expanded(child: buildLoadingTile("Sale Loading..."));
                } else if (asyncSnapshot.hasError) {
                  return _buildStatCard(
                    "Total Sale Amount",
                    "Error ${asyncSnapshot.error}",
                    Icons.money,
                    Colors.green,
                  );
                } else {
                  final saleData = asyncSnapshot.data![0];
                  final pointsData = asyncSnapshot.data![1];
                  final issuedPointsData = asyncSnapshot.data![2];

                  print("Sale Data: ${saleData['totalAmount']}");
                  print("Points Data: $pointsData");
                  print("Issued Points Data: $issuedPointsData");
                  return Row(
                    children: [
                      _buildStatCard(
                        "Total Sale Amount",
                        "${formatter.format(saleData['totalAmount'])} Ks",
                        Icons.money,
                        Colors.green,
                      ),

                      const SizedBox(width: 15),
                      _buildStatCard(
                        "Total Sale Liter",
                        "${formatter.format(saleData['totalLiter'])} Lit",
                        Icons.water_drop_outlined,
                        Colors.grey,
                      ),
                      const SizedBox(width: 15),
                      _buildStatCard(
                        "Total Rewards",
                        "${pointsData[0]['station_id']}" == "No Data"
                            ? "${0} Pts"
                            : "${pointsData[0]['total_points']} Pts",
                        //"${formatter.format(pointsData['total_pints'])} Pts",
                        Icons.card_giftcard,
                        Colors.orange,
                      ),
                      const SizedBox(width: 15),
                      _buildStatCard(
                        "Points Issued",
                        "${issuedPointsData[0]['station_id']}" == "No Data"
                            ? "${0} Pts"
                            : "${issuedPointsData[0]['total_points']} Pts",
                        // "${issuedPointsData['station_id']}" == 'No Data'
                        //     ? "${0} Pts"
                        //     : "${issuedPointsData[0]['total_points']} Pts",
                        Icons.stars,
                        Colors.green,
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 30),

            // ၂။ အောက်က Main Content (Charts နှင့် Recent List)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ဘယ်ဘက်ခြမ်း - Summary/Charts နေရာ
                  Expanded(flex: 2, child: buildSummaryGrid()),
                  const SizedBox(width: 20),

                  // ညာဘက်ခြမ်း - Recent Redemptions
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recent Redemptions",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: buildRedemptionHistory()), // အစောက လုပ်ထားတဲ့ list
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Statistics Card Builder
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> getSummaryData() async {
    final response = await http.get(Uri.parse('${AppConfig.apiUrl}/api/summary/data'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load summary data ${response.statusCode}');
    }
  }

  // Supabase ကနေ ဒီနေ့အတွက် စုစုပေါင်း Point ကို ယူတဲ့ function
  Future<List<Map<String, dynamic>>> getPointsSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      final response = await Supabase.instance.client.rpc(
        'get_points_summary_by_station',
        params: {'start_date': todayStart},
      );

      // Data မရှိရင်တောင် Empty List [] ပြန်လာမှာဖြစ်လို့ null check လုပ်စရာမလိုတော့ဘူး
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      // Error တက်ခဲ့ရင်တောင် Application မရပ်သွားအောင် Default Map တစ်ခု ပို့ပေးမယ်
      print('RPC Error: $e');
      return [
        {'station_id': 'Error', 'total_points': 0},
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getIssuedPointsSummary() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      final response = await Supabase.instance.client.rpc(
        'get_issued_points_summary_by_station',
        params: {'start_date': todayStart},
      );

      // Data မရှိရင်တောင် Empty List [] ပြန်လာမှာဖြစ်လို့ null check လုပ်စရာမလိုတော့ဘူး
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      // Error တက်ခဲ့ရင်တောင် Application မရပ်သွားအောင် Default Map တစ်ခု ပို့ပေးမယ်
      print('RPC Error: $e');
      return [
        {'station_id': 'Error', 'total_points': 0},
      ];
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
import 'package:station_msloyalty/Services/FuelTypeStorage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final StreamController<SalesLoadStatus> salesStreamController =
    StreamController<SalesLoadStatus>.broadcast();

// NumberFormat ကို ကြေညာမယ်
final formatter = NumberFormat('#,###');

// Supabase ကနေ နောက်ဆုံး ၂၀ ခုကို Stream နဲ့ ယူမယ်
Stream<List<Map<String, dynamic>>> get recentCollectedStream {
  return Supabase.instance.client
      .from('fuel_transactions')
      .stream(primaryKey: ['id'])
      .eq('station_id', AppConfig.stationId)
      .order('created_at', ascending: false)
      .limit(20);
}

// Sale Types များကို API မှယူပြီး Local သိမ်းခြင်း
Future<void> syncSaleTypes() async {
  try {
    print("Syncing Sale Types from ${AppConfig.apiUrl}/api/saletypes...");
    final response = await http
        .get(Uri.parse("${AppConfig.apiUrl}/api/saletypes"))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_sale_types', jsonEncode(data));
      print("Sale Types Synced successfully from API");
    } else {
      print("Sale Types API Error: ${response.statusCode}");
      throw "Failed to sync Sale Types from API: ${response.statusCode}";
    }
  } catch (e) {
    print("Sale Types Sync Exception: $e");
    rethrow;
  }
}

Future<void> syncFuelTypes() async {
  try {
    // သားကြီးရဲ့ API URL ကို ဒီမှာ ထည့်ပါ
    final response = await http
        .get(Uri.parse("${AppConfig.apiUrl}/api/fueltypes"))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> fuelData = jsonDecode(response.body);

      // ရလာတဲ့ data ကို Local Storage မှာ သိမ်းမယ်
      await FuelTypeStorage.saveFuelTypes(fuelData);
      print("Fuel Types Synced successfully from API");
    } else {
      print("API Error: ${response.statusCode}");
    }
  } catch (e) {
    print("Connection Error: $e");
  }
}

// Reward Title ယူရန် (image_6e62a2.png ရှိ gift_cards ထဲကယူမည်)
Future<String> getRewardTitle(int rewardId) async {
  final data = await Supabase.instance.client
      .from('gift_cards')
      .select('title')
      .eq('id', rewardId)
      .single();
  return data['title'] ?? 'Reward';
}

// User Name ယူရန်
Future<String> getUserName(String userId) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .single();
  return data['full_name'] ?? 'Unknown';
}

// Future<int> getTotalRedeemed() async {
//   final res = await Supabase.instance.client
//       .from('redemption_history')
//       .select('id', const FetchOptions(count: CountOption.exact));
//   return res.count;
// }

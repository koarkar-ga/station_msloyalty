import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/Model/FuelTypeMode.dart';

class FuelTypeStorage {
  static const String _key = 'fuel_types_list';

  // ၁။ Database ကလာတဲ့ list ကို သိမ်းမယ်
  static Future<void> saveFuelTypes(List<dynamic> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(data);
    await prefs.setString(_key, encodedData);
  }

  // ၂။ Local ထဲက data ကို ပြန်ယူမယ်
  static Future<List<FuelType>> getFuelTypes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => FuelType.fromJson(item)).toList();
  }
}

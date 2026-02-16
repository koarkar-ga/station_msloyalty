import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<List<dynamic>> getSaleTypesLocal() async {
  final prefs = await SharedPreferences.getInstance();
  String? encodedData = prefs.getString('local_sale_types');

  if (encodedData != null) {
    return jsonDecode(encodedData); // String ကို List ပြန်ပြောင်းမယ်
  }
  return [];
}

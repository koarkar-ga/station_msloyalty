// API Connection အခြေအနေကို စစ်ဆေးခြင်း
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:station_msloyalty/AppConfig.dart';

Future<bool> checkConnection(BuildContext context, bool isStatus) async {
  bool _isStatus = false;
  try {
    final response = await http
        .get(Uri.parse(AppConfig.apiHealthUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      if (context.mounted) {
        isStatus = true;
      }
    }
    print("API Status: ${response.statusCode}");
  } catch (e) {
    if (context.mounted) {
      isStatus = false;
    }
    print(e.toString());
  }
  _isStatus = isStatus;
  return _isStatus;
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:station_msloyalty/AppConfig.dart';
import '../Model/SensorData.dart';

class SensorService {
  Future<List<SensorData>> fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/sensors'),
        headers: AppConfig.headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      rethrow;
    }
  }
}

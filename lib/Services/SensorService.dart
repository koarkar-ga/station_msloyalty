import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/SensorData.dart';

class SensorService {
  // Use the local IP address of the machine running the Rust backend.
  // For development on the same machine, 'localhost' or '127.0.0.1' works.
  static const String _baseUrl = 'http://localhost:3000/api';

  Future<List<SensorData>> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/sensors'));

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

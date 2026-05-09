class SensorData {
  final String tankName;
  final String fuelName;
  final double level;
  final double water;
  final double temperature;
  final DateTime lastUpdated;
  final double capacity;

  SensorData({
    required this.tankName,
    required this.fuelName,
    required this.level,
    required this.water,
    required this.temperature,
    required this.lastUpdated,
    required this.capacity,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      tankName: json['tankName'] ?? 'Unknown Tank',
      fuelName: json['fuelName'] ?? 'Unknown Fuel',
      level: (json['level'] as num).toDouble(),
      water: (json['water'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      capacity: (json['capacity'] as num).toDouble(),
    );
  }

  factory SensorData.empty() {
    return SensorData(
      tankName: 'Loading...',
      fuelName: 'Loading...',
      level: 0.0,
      water: 0.0,
      temperature: 0.0,
      lastUpdated: DateTime.now(),
      capacity: 0.0,
    );
  }
}

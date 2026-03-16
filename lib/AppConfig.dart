import 'dart:io';
import 'package:ini/ini.dart';
import 'package:path/path.dart' as p; // 'path' package ကို pubspec.yaml မှာ ထည့်ပေးပါ

class AppConfig {
  static bool configExists = false;
  static String stationName = "MOONSUN"; // Default value
  static String stationId = "M001";
  static String host = "localhost";
  static String username = "sa";
  static String password = "infosys2011iss@";
  static String database = "M001";
  static String exportPath = "";
  static String apiUrl = "http://localhost:3000";
  static String apiHealthUrl = "${AppConfig.apiUrl}/api/health";
  static int currentUserLevel = 11; // Default to basic level
  static String? currentUserId;
  static String? currentUserName;

  static Future<void> loadConfig() async {
    try {
      String exePath = Platform.resolvedExecutable;
      String exeDir = p.dirname(exePath);
      String configPath = p.join(exeDir, 'config.ini');
      File configFile = File(configPath);

      if (await configFile.exists()) {
        configExists = true;
        List<String> lines = await configFile.readAsLines();
        Config config = Config.fromStrings(lines);

        stationName = config.get("station", "name") ?? "Moon Sun";
        stationId = config.get("station", "id") ?? "M001";

        username = config.get("database", "username") ?? "sa";
        password = config.get("database", "password") ?? "infosys2011iss@";
        database = config.get("database", "database") ?? "M001";
        host = config.get("database", "server") ?? "localhost";

        apiUrl = config.get("api", "url") ?? "http://localhost:3000";
        apiHealthUrl = "${AppConfig.apiUrl}/api/health";

        exportPath = "$exeDir/reports";
        print("Config Loaded from: $configPath");
      } else {
        configExists = false;
        print("config.ini not found at $configPath. Using defaults.");
      }
    } catch (e) {
      print("Error loading config: $e");
    }
  }

  static Future<void> saveConfig({
    required String name,
    required String id,
    required String dbHost,
    required String dbUser,
    required String dbPass,
    required String dbName,
    required String api,
  }) async {
    try {
      String exePath = Platform.resolvedExecutable;
      String exeDir = p.dirname(exePath);
      String configPath = p.join(exeDir, 'config.ini');
      
      final config = Config();
      config.addSection("station");
      config.set("station", "name", name);
      config.set("station", "id", id);
      
      config.addSection("database");
      config.set("database", "server", dbHost);
      config.set("database", "username", dbUser);
      config.set("database", "password", dbPass);
      config.set("database", "database", dbName);
      
      config.addSection("api");
      config.set("api", "url", api);

      File configFile = File(configPath);
      await configFile.writeAsString(config.toString());
      
      // Reload values after saving
      await loadConfig();
    } catch (e) {
      print("Error saving config: $e");
      rethrow;
    }
  }
}

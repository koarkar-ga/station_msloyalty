import 'dart:io';
import 'package:ini/ini.dart';
import 'package:path/path.dart' as p; // 'path' package ကို pubspec.yaml မှာ ထည့်ပေးပါ

class AppConfig {
  static String stationName = "MOONSUN"; // Default value
  static String stationId = "M001";
  static String host = "localhost";
  static String username = "sa";
  static String password = "infosys2011iss@";
  static String database = "M001";
  static String exportPath = "";
  static String apiUrl = "http://localhost:3000";

  static Future<void> loadConfig() async {
    try {
      // ၁။ Executable ရှိတဲ့ Folder Path ကို ယူပါ
      String exePath = Platform.resolvedExecutable;
      String exeDir = p.dirname(exePath);

      // ၂။ အဲဒီ Folder ထဲက config.ini file path ကို တည်ဆောက်ပါ
      String configPath = p.join(exeDir, 'config.ini');
      File configFile = File(configPath);

      if (await configFile.exists()) {
        List<String> lines = await configFile.readAsLines();
        Config config = Config.fromStrings(lines);

        // ၃။ Data များ ဆွဲထုတ်ယူခြင်း
        stationName = config.get("station", "name") ?? "Moon Sun";
        stationId = config.get("station", "id") ?? "M001";

        username = config.get("database", "username") ?? "sa";
        password = config.get("database", "password") ?? "infosys2011iss@";
        database = config.get("database", "database") ?? "M001";
        host = config.get("database", "server") ?? "localhost";

        apiUrl = config.get("api", "url") ?? "http://localhost:3000";

        exportPath = "$exeDir/reports";

        print("Config Loaded from: $configPath");
      } else {
        // File မရှိရင် Default Config တစ်ခု အလိုအလျောက် ဆောက်ပေးနိုင်ပါတယ် (Optional)
        print("config.ini not found at $configPath. Using defaults.");
      }
    } catch (e) {
      print("Error loading config: $e");
    }
  }
}

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:station_msloyalty/Model/AppSettings.dart';

class AppConfig {
  static late Isar isar;
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
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [AppSettingsSchema],
        directory: dir.path,
      );

      final settings = await isar.appSettings.where().findFirst();

      if (settings != null) {
        configExists = true;
        stationName = settings.stationName ?? "MOONSUN";
        stationId = settings.stationId ?? "M001";
        host = settings.dbHost ?? "localhost";
        username = settings.dbUser ?? "sa";
        password = settings.dbPass ?? "infosys2011iss@";
        database = settings.dbName ?? "M001";
        apiUrl = settings.apiUrl ?? "http://localhost:3000";
        apiHealthUrl = "$apiUrl/api/health";
        
        print("Config Loaded from Isar");
      } else {
        configExists = false;
        print("No settings found in Isar. Using defaults.");
      }
      
      final docDir = await getApplicationDocumentsDirectory();
      exportPath = "${docDir.path}/reports";
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
      final settings = await isar.appSettings.where().findFirst() ?? AppSettings();
      
      settings.stationName = name;
      settings.stationId = id;
      settings.dbHost = dbHost;
      settings.dbUser = dbUser;
      settings.dbPass = dbPass;
      settings.dbName = dbName;
      settings.apiUrl = api;

      await isar.writeTxn(() async {
        await isar.appSettings.put(settings);
      });
      
      // Update static values
      stationName = name;
      stationId = id;
      host = dbHost;
      username = dbUser;
      password = dbPass;
      database = dbName;
      apiUrl = api;
      apiHealthUrl = "$apiUrl/api/health";
      configExists = true;

      print("Config Saved to Isar");
    } catch (e) {
      print("Error saving config: $e");
      rethrow;
    }
  }
}

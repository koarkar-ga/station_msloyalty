import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:station_msloyalty/Model/AppSettings.dart';
import 'package:station_msloyalty/Model/OfflineTransaction.dart';

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
  static String port = "1433";
  static bool isHoConfig = false;
  static String apiHealthUrl = "${AppConfig.apiUrl}/api/health";
  static int currentUserLevel = 11; // Default to basic level
  static String? currentUserId;
    static String? currentUserName;
  static Map<String, bool> permissions = {};

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'x-station-id': stationId,
  };

  static Future<void> loadConfig() async {
    try {
      final dir = await getApplicationSupportDirectory();
      isar = await Isar.open(
        [AppSettingsSchema, OfflineTransactionSchema],
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
        port = settings.dbPort ?? "1433";
        isHoConfig = settings.isHoConfig;
        apiHealthUrl = "$apiUrl/api/health";

        print(
          "Config Loaded from Isar: Name=$stationName, ID=$stationId, Host=$host, Port=$port, User=$username, DB=$database, API=$apiUrl, HO=$isHoConfig",
        );
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
    String dbPort = "1433",
    bool hoConfig = false,
  }) async {
    try {
      final settings =
          await isar.appSettings.where().findFirst() ?? AppSettings();

      settings.stationName = name;
      settings.stationId = id;
      settings.dbHost = dbHost;
      settings.dbUser = dbUser;
      settings.dbPass = dbPass;
      settings.dbName = dbName;
      settings.apiUrl = api;
      settings.dbPort = dbPort;
      settings.isHoConfig = hoConfig;

      await isar.writeTxn(() async {
        final id = await isar.appSettings.put(settings);
        print("Config persisted with ID: $id");
      });

      // Update static values
      stationName = name;
      stationId = id;
      host = dbHost;
      username = dbUser;
      password = dbPass;
      database = dbName;
      apiUrl = api;
      port = dbPort;
      isHoConfig = hoConfig;
      apiHealthUrl = "$apiUrl/api/health";
      configExists = true;

      print(
        "Config Saved to Isar: Name=$name, ID=$id, Host=$dbHost, Port=$dbPort, User=$dbUser, DB=$dbName, API=$api, HO=$hoConfig",
      );
    } catch (e) {
      print("Error saving config: $e");
      rethrow;
    }
  }

  static Future<bool> verifyPersistence() async {
    try {
      final settings = await isar.appSettings.where().findFirst();
      if (settings != null) {
        print("Verification Success: Station ID = ${settings.stationId}");
        return true;
      }
      print("Verification Failed: No settings found in Isar.");
      return false;
    } catch (e) {
      print("Verification Error: $e");
      return false;
    }
  }

  static Future<void> updatePosApiConfig(String newDbName) async {
    try {
      // Find pos-api/config.ini.
      // In development, it's a sibling to the project root.
      // We'll try to find it relative to the executable or use a standard relative path.

      // For the user's current environment:
      // /Users/prom1/DEV/station_msloyalty (project)
      // /Users/prom1/DEV/pos-api/config.ini (target)

      // We can try to get the parent directory of the current project root.
      // However, we'll start with a few likely locations.

      List<String> possiblePaths = [
        '../pos-api/config.ini', // Sibling in DEV
        'pos-api/config.ini', // Subfolder (unlikely but possible)
        '../../pos-api/config.ini', // Another sibling possibility
      ];

      File? configFile;
      for (String path in possiblePaths) {
        final f = File(path);
        if (await f.exists()) {
          configFile = f;
          break;
        }
      }

      if (configFile == null) {
        print(
          "updatePosApiConfig: pos-api/config.ini not found in expected locations.",
        );
        return;
      }

      final lines = await configFile.readAsLines();
      bool isInDatabaseSection = false;
      bool isUpdated = false;

      final newLines = lines.map((line) {
        final trimmedLine = line.trim();

        if (trimmedLine.startsWith('[database]')) {
          isInDatabaseSection = true;
          return line;
        } else if (trimmedLine.startsWith('[') && trimmedLine.endsWith(']')) {
          isInDatabaseSection = false;
          return line;
        }

        if (isInDatabaseSection && trimmedLine.startsWith('database')) {
          final parts = line.split('=');
          if (parts.length == 2) {
            final currentValue = parts[1].trim();
            if (currentValue == 'HO') {
              isUpdated = true;
              return "${parts[0]}= $newDbName";
            }
          }
        }
        return line;
      }).toList();

      if (isUpdated) {
        await configFile.writeAsString(newLines.join('\n'));
        print(
          "updatePosApiConfig: Successfully updated ${configFile.path} database to $newDbName",
        );
      }
    } catch (e) {
      print("Error updating pos-api config: $e");
    }
  }
}

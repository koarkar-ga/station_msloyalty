import 'package:isar/isar.dart';

part 'AppSettings.g.dart';

@collection
class AppSettings {
  Id id = Isar.autoIncrement;

  String? stationName;
  String? stationId;
  String? dbHost;
  String? dbUser;
  String? dbPass;
  String? dbName;
  String? dbPort;
  String? apiUrl;
  bool isHoConfig = false;
  bool useCameraScanner = false;
}

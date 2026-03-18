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
  String? apiUrl;
  bool useCameraScanner = false;
}

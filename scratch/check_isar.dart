import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:station_msloyalty/Model/AppSettings.dart';

Future<void> main() async {
  final dir = await getApplicationSupportDirectory();
  final isar = await Isar.open(
    [AppSettingsSchema],
    directory: dir.path,
  );

  final settings = await isar.appSettings.where().findFirst();
  if (settings != null) {
    print("Isar Settings: ID=${settings.stationId}, DB=${settings.dbName}");
  } else {
    print("No settings found in Isar.");
  }
  await isar.close();
}

import 'package:isar/isar.dart';

part 'OfflineTransaction.g.dart';

enum OfflineActionType { earn, redeem }

@collection
class OfflineTransaction {
  Id id = Isar.autoIncrement;

  @Index()
  @Enumerated(EnumType.name)
  OfflineActionType actionType = OfflineActionType.earn;

  String? targetUid;
  String? dynamicTokenId; // For EARN|... format
  String? stationId;
  
  // For Earn
  String? fuelType;
  double? amountMmk;
  @Index()
  String? vocNo;
  String? saleType;
  String? vehicleNo;
  String? paymentType;
  double? unitPrice;
  double? saleLiter;

  // For Redeem
  int? rewardId;
  int? requiredPoints;

  @Index()
  DateTime? createdAt;

  @Index()
  bool isSynced = false;
  String? syncError; // To store failure reasons
}

import 'dart:convert';

class FuelType {
  final int fuelTypeCode;
  final String fuelTypeName;
  //final int mainCode;

  FuelType({required this.fuelTypeCode, required this.fuelTypeName}); //required this.mainCode

  // JSON အဖြစ်ပြောင်းရန်
  Map<String, dynamic> toJson() => {
    'FuelTypeCode': fuelTypeCode,
    'FuelTypeName': fuelTypeName,
    //'maincode': mainCode,
  };

  // JSON ကနေ Model ပြန်ပြောင်းရန်
  factory FuelType.fromJson(Map<String, dynamic> json) => FuelType(
    fuelTypeCode: json['FuelTypeCode'],
    fuelTypeName: json['FuelTypeName'],
    //mainCode: json['maincode'],
  );
}

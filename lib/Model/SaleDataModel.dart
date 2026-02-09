class SaleData {
  final String grade; // e.g., "HSD", "OCT(92)"
  final double saleLiter; // e.g., 20.5
  final double literPrice; // e.g., 2950
  final double saleAmount; // e.g., 60475

  SaleData({
    required this.grade,
    required this.saleLiter,
    required this.literPrice,
    required this.saleAmount,
  });

  // Database သို့မဟုတ် CSV မှ map ရန်
  factory SaleData.fromMap(Map<String, dynamic> map) {
    return SaleData(
      grade: map['FuelTypeName'] ?? 'Unknown',
      saleLiter: double.tryParse(map['SALELITER']?.toString() ?? '0') ?? 0,
      literPrice: double.tryParse(map['TodayPrice']?.toString() ?? '0') ?? 0,
      saleAmount: double.tryParse(map['TotalPrice']?.toString() ?? '0') ?? 0,
    );
  }
}

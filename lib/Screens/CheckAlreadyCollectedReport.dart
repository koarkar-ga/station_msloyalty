import 'package:flutter/material.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/TextFieldDialog.dart';
import 'package:station_msloyalty/Services/CheckVocNoExists.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckAlreadyCollectedReport extends StatelessWidget {
  final Map<String, dynamic> sale;
  final SupabaseClient supabase;

  const CheckAlreadyCollectedReport({
    super.key,
    required this.sale,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    // Report screen မှာ data က VocNo ပဲပါတယ်။ fullVocNo က station prefix လိုတယ်။
    final String fullVocNo = "${AppConfig.stationId}${sale['VocNo']}";
    return StreamBuilder<bool>(
      stream: checkIfExistsStream(fullVocNo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.data == true) {
          return const Tooltip(
            message: "Point Collect လုပ်ပြီးပါပြီ",
            child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          );
        }

        return TextFieldDialog(
          supabase: supabase,
          voc_no: sale['VocNo'],
          vehical_no: sale['Vehical_No'] ?? '',
          fuel_type: sale['FuelTypeName'] ?? '',
          amount: sale['TotalPrice']?.toString() ?? '0',
          sale_type: sale['Sale_Type_name'] ?? '',
        );
      },
    );
  }
}

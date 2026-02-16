import 'package:supabase_flutter/supabase_flutter.dart';

Stream<bool> checkIfExistsStream(String fullVocNo) {
  return Supabase.instance.client
      .from('fuel_transactions')
      .stream(primaryKey: ['id']) // Real-time အတွက် primary key ပေးရတယ်
      .eq('voc_no', fullVocNo)
      .map((data) => data.isNotEmpty); // list ထဲမှာ data ပါလာရင် true
}

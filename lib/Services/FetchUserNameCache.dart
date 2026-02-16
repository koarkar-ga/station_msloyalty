// Class အပေါ်မှာ ဒါလေး အရင်ကြေညာထားပါ
import 'package:supabase_flutter/supabase_flutter.dart';

final Map<String, String> _userNameCache = {};

Future<String> fetchUserName(String userId) async {
  // ၁။ Cache ထဲမှာ ရှိပြီးသားလား အရင်စစ်မယ်
  if (_userNameCache.containsKey(userId)) {
    return _userNameCache[userId]!;
  }

  try {
    // ၂။ မရှိသေးရင် Supabase ကနေ သွားယူမယ်
    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

    final String name = data['full_name'] ?? 'Unknown User';

    // ၃။ ရလာတဲ့နာမည်ကို နောက်တစ်ခါသုံးရအောင် သိမ်းထားမယ်
    _userNameCache[userId] = name;
    return name;
  } catch (e) {
    return 'User ($userId)'; // Error ဖြစ်ရင် ID ပဲ ပြထားမယ်
  }
}

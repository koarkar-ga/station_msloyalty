import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    try {
      // maybeSingle() ကို သုံးထားလို့ user မရှိရင် error မတက်ဘဲ null ပြန်ပေးပါမယ်

      final data = await supabase
          .from('auth')
          .select('*')
          .eq('username', username.trim())
          .eq('password', password.trim())
          .maybeSingle();

      if (data != null) {
        return {
          'id': data['uuid'],
          'userlevel': data['userlevel'],
          'station_code': data['station_code'],
          'status': 'success',
          'message': 'Login Successful'
        };
      } else {
        return {'id': null, 'userlevel': null, 'status': 'error', 'message': 'Username (သို့မဟုတ်) password မမှန်ပါ။'};
      }

      //print("Login Success: ${data!['id']}");

      return null; // Error မရှိဘူးလို့ အဓိပ္ပာယ်ရပါတယ်
    } catch (e) {
      return {'id': null, 'status': 'error', 'message': 'Login Failed, ${e.toString()}'};
    }
  }
}

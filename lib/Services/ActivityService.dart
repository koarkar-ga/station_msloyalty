import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/AppConfig.dart';

class ActivityService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> logActivity({
    required String actionType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('activities').insert({
        'user_id': AppConfig.currentUserId,
        'user_name': AppConfig.currentUserName,
        'action_type': actionType,
        'description': description,
        'station_id': AppConfig.stationId,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }
}

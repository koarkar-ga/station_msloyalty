import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/AppConfig.dart';

class FuelPriceService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchLatestPrices() async {
    try {
      // 1. Try to fetch by station_id first
      final stationData = await supabase
          .from('fuel_prices')
          .select('*')
          .eq('station_id', AppConfig.stationId)
          .order('updated_at', ascending: false)
          .maybeSingle();

      if (stationData != null) {
        return stationData;
      }

      // 2. If no station-specific prices, fetch by region
      // We need to find the region of the current station first
      final stationInfo = await supabase
          .from('stations')
          .select('region')
          .eq('station_id', AppConfig.stationId)
          .maybeSingle();

      if (stationInfo != null && stationInfo['region'] != null) {
        final regionData = await supabase
            .from('fuel_prices')
            .select('*')
            .eq('region', stationInfo['region'])
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (regionData != null) {
          return regionData;
        }
      }

      // 3. Last fallback: Global/Default prices (e.g., Yangon)
      final defaultData = await supabase
          .from('fuel_prices')
          .select('*')
          .eq('region', 'Yangon')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return defaultData;
    } catch (e) {
      print('Error fetching fuel prices: $e');
      return null;
    }
  }
}

class DuplicateAnalysisHelper {
  /// Analyzes the sales data for suspicious duplicate patterns.
  /// Identifies same vehicle refills at different stations or with different fuel types.
  static List<Map<String, dynamic>> analyzeDuplicates(List<dynamic> salesData, {List<String>? excludePrefixes}) {
    // 1. Group by Vehicle No
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var sale in salesData) {
      final vehNo = (sale['Vehical_No'] ?? '').toString().trim();
      if (vehNo.isEmpty || vehNo == '-') continue;

      // Exclude specific prefixes if requested
      if (excludePrefixes != null && excludePrefixes.isNotEmpty) {
        bool shouldExclude = false;
        final upperVehNo = vehNo.toUpperCase();
        for (var prefix in excludePrefixes) {
          if (upperVehNo.startsWith(prefix.toUpperCase())) {
            shouldExclude = true;
            break;
          }
        }
        if (shouldExclude) continue;
      }
      
      if (!grouped.containsKey(vehNo)) {
        grouped[vehNo] = [];
      }
      grouped[vehNo]!.add(Map<String, dynamic>.from(sale));
    }

    final List<Map<String, dynamic>> results = [];

    // 2. Analyze groups
    grouped.forEach((vehNo, records) {
      // Sort by date/time
      records.sort((a, b) {
        final dateA = DateTime.parse(a['S_Date']);
        final dateB = DateTime.parse(b['S_Date']);
        return dateA.compareTo(dateB);
      });

      // Calculate time differences and flag suspicious patterns
      for (int i = 0; i < records.length; i++) {
        final current = records[i];
        String timeDiff = "-";
        bool isSuspicious = false;
        List<String> reasons = [];

        if (i > 0) {
          final previous = records[i - 1];
          final datePrev = DateTime.parse(previous['S_Date']);
          final dateCurr = DateTime.parse(current['S_Date']);
          final diff = dateCurr.difference(datePrev);
          
          timeDiff = _formatDuration(diff);

          // Check for different Fuel Type
          if (current['FuelTypeName'] != previous['FuelTypeName']) {
            isSuspicious = true;
            reasons.add("Fuel Type လွှဲနေသည် (${previous['FuelTypeName']} -> ${current['FuelTypeName']})");
          }

          // Check for different Station
          if (current['station_id'] != previous['station_id']) {
            isSuspicious = true;
            reasons.add("Station မတူပဲ ထပ်ဖြည့်သည် (${previous['station_name']} -> ${current['station_name']})");
          }
          
          // Same station but suspicious if VERY short time (e.g. < 5 mins)
          if (diff.inMinutes < 5 && current['station_id'] == previous['station_id']) {
            isSuspicious = true;
            reasons.add("အချိန်တိုအတွင်း ထပ်ဖြည့်သည် (${diff.inMinutes} mins)");
          }
        }

        current['analysis_time_diff'] = timeDiff;
        current['is_suspicious'] = isSuspicious;
        current['suspicious_reason'] = reasons.join(", ");
        
        // Add all records of vehicles that have at least one duplicate
        if (records.length > 1) {
           results.add(current);
        }
      }
    });

    // Final sorting of results by time descending (newest first)
    results.sort((a, b) => DateTime.parse(b['S_Date']).compareTo(DateTime.parse(a['S_Date'])));
    
    return results;
  }

  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return "${duration.inDays}d ${duration.inHours % 24}h";
    if (duration.inHours > 0) return "${duration.inHours}h ${duration.inMinutes % 60}m";
    if (duration.inMinutes > 0) return "${duration.inMinutes}m";
    return "${duration.inSeconds}s";
  }
}

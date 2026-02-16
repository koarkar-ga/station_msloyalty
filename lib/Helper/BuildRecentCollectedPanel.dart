import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Services/FetchUserNameCache.dart';

Widget buildRecentCollectedPanel() {
  return Column(
    // Error က ဒီကောင်မှာ တက်နေတာ
    children: [
      // ၁။ Header (စာသား)
      Container(
        padding: const EdgeInsets.all(11),
        width: double.infinity,
        color: Colors.blueGrey[800],
        child: const Text(
          "Recent Collected (Last 20)",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      // ၂။ List အပိုင်း (ဒါကို Expanded မအုပ်ရင် 'hasSize' error တက်မယ်)
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: recentCollectedStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(
                child: SizedBox(width: 200, height: 10, child: const LinearProgressIndicator()),
              );

            // StreamBuilder ရဲ့ builder ထဲမှာ ဒါလေးသေချာထည့်ပါ
            final items = List.from(snapshot.data!); // original list ကို copy ယူ
            items.sort(
              (a, b) => b['created_at'].compareTo(a['created_at']),
            ); // အသစ်ဆုံးကို အပေါ်တင်

            return ListView.builder(
              // ၃။ Key ထည့်ပေးတာက List ကို အပေါ်ဆုံးကနေ Refresh ဖြစ်စေတယ်
              key: ValueKey(items.isNotEmpty ? items.first['id'] : 'empty'),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildRecentItemCard(items[index]);
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildRecentItemCard(dynamic item) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade100),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade50,
            child: FutureBuilder<String>(
              future: fetchUserName(item['user_id']),
              builder: (context, asyncSnapshot) {
                return Text(
                  (asyncSnapshot.data ?? "U")[0].toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: fetchUserName(item['user_id']),
                  builder: (context, asyncSnapshot) {
                    return Text(
                      asyncSnapshot.data ?? "Unknown User",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Voucher No with Icon
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      item['voc_no'] ?? "-",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd-MM-yyyy').format(DateTime.parse(item['created_at'])),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm a').format(DateTime.parse(item['created_at'])),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Point Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              "+${item['points_earned']} Pts",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Icon နဲ့ Text ကို တွဲပြမယ့် Helper Small Widget
Widget _buildInfoRow(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
    ],
  );
}

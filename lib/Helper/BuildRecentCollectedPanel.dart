import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Services/FetchUserNameCache.dart';

Widget buildRecentCollectedPanel() {
  return Column(
    children: [
      // ၁။ Header (စာသား)
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A192F), Color(0xFF132B4F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const Text(
          "RECENT COLLECTED",
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ၂။ List အပိုင်း
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: recentCollectedStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 150,
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4F72)),
                  ),
                ),
              );
            }

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            
            final items = (snapshot.data ?? []).where((item) {
              final createdAt = DateTime.parse(item['created_at']).toLocal();
              final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
              return itemDate.isAtSameMomentAs(today);
            }).toList();
            
            items.sort((a, b) => b['created_at'].compareTo(a['created_at']));

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
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
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          // User Avatar with Gradient
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1B4F72).withValues(alpha: 0.1), const Color(0xFF1B4F72).withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: FutureBuilder<String>(
              future: fetchUserName(item['user_id']),
              builder: (context, asyncSnapshot) {
                return Center(
                  child: Text(
                    (asyncSnapshot.data ?? "U")[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1B4F72),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),

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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // Voucher No with Icon
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 14, color: Colors.blueGrey[300]),
                    const SizedBox(width: 4),
                    Text(
                      item['voc_no'] ?? "-",
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.blueGrey[200]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(item['created_at']).toLocal()),
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey[300]),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey[200]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm aa').format(DateTime.parse(item['created_at']).toLocal()),
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey[300]),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "+${item['points_earned']}",
              style: const TextStyle(
                color: Color(0xFF059669),
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

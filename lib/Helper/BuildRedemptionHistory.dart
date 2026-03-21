import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedemptionHistoryList extends StatefulWidget {
  const RedemptionHistoryList({super.key});

  @override
  State<RedemptionHistoryList> createState() => _RedemptionHistoryListState();
}

class _RedemptionHistoryListState extends State<RedemptionHistoryList> {
  late final Stream<List<Map<String, dynamic>>> _historyStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream ONLY ONCE to prevent infinite build loops
    final query = Supabase.instance.client
        .from('redemption_history')
        .stream(primaryKey: ['id']);

    if (AppConfig.stationId != 'ALL') {
      _historyStream = query
          .eq('station_id', AppConfig.stationId)
          .order('created_at', ascending: false)
          .limit(10);
    } else {
      _historyStream = query.order('created_at', ascending: false).limit(10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(color: Colors.red),
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final history = (snapshot.data ?? []).where((item) {
          final createdAt = DateTime.parse(item['created_at']).toLocal();
          final itemDate = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          );
          return itemDate.isAtSameMomentAs(today);
        }).toList();

        if (history.isEmpty) {
          return const Center(
            child: Text(
              "No Redemption History",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return RedemptionCard(data: item);
          },
        );
      },
    );
  }
}

class RedemptionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const RedemptionCard({super.key, required this.data});

  @override
  State<RedemptionCard> createState() => _RedemptionCardState();
}

class _RedemptionCardState extends State<RedemptionCard> {
  late Future<String> _userNameFuture;
  late Future<String> _rewardTitleFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = getUserName(widget.data['user_id']);
    _rewardTitleFuture = getRewardTitle(widget.data['reward_id']);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // ၁။ Icon Section
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // ၂။ Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _userNameFuture,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading...',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                FutureBuilder<String>(
                  future: _rewardTitleFuture,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? '...',
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                // အချိန်ပြမယ်
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 10,
                      color: Colors.blueGrey[200],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy hh:mm aa',
                      ).format(DateTime.parse(data['created_at']).toLocal()),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blueGrey[300],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ၃။ Points Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "-${data['points_spent']}",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Text(
                "PTS",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

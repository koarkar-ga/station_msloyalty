// Right Side History Builder
import 'package:flutter/material.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget buildRedemptionHistory() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    // redemption_history table ကို realtime နားထောင်မယ်
    stream: Supabase.instance.client
        .from('redemption_history')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false) // အသစ်ဆုံးကို အပေါ်ထားမယ်
        .limit(10),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      final history = snapshot.data!;
      if (snapshot.data!.isEmpty) {
        return Center(
          child: Text("No Redemption History", style: TextStyle(color: Colors.grey)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return buildRedemptionCard(item);
        },
      );
    },
  );
}

Widget buildRedemptionCard(Map<String, dynamic> data) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    elevation: 0,
    color: Colors.blueGrey[50]?.withOpacity(0.5), // ပုံထဲကလို မှိန်မှိန်လေး
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: FutureBuilder<String>(
        // User ID ကနေ နာမည်လှမ်းယူမယ်
        future: getUserName(data['user_id']),
        builder: (context, nameSnapshot) {
          return Text(
            "User: ${nameSnapshot.data ?? 'Loading...'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          );
        },
      ),
      subtitle: FutureBuilder<String>(
        // Reward ID ကနေ ပစ္စည်းနာမည် လှမ်းယူမယ်
        future: getRewardTitle(data['reward_id']),
        builder: (context, rewardSnapshot) {
          return Text(
            "Item: ${rewardSnapshot.data ?? '...'}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          );
        },
      ),
      trailing: Text(
        "-${data['points_spent']} Pts",
        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
  );
}

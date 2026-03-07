import 'package:flutter/material.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget buildRewardGridView() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    // Gift Cards table ကနေ realtime data ယူမယ်
    stream: Supabase.instance.client
        .from('gift_cards')
        .stream(primaryKey: ['id'])
        .eq('is_available', true) // ရနိုင်တာတွေပဲ ပြမယ်
        .order('points_required', ascending: true),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

      final cards = snapshot.data!.map((map) => GiftCard.fromMap(map)).toList();

      return GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // တစ်တန်းကို ၅ ခုပြမယ် (Desktop/Tablet အတွက်)
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.8, // Card ရဲ့ အချိုးအစား
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return _buildGiftCardItem(cards[index]);
        },
      );
    },
  );
}

Widget _buildGiftCardItem(GiftCard card) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ၁။ ပစ္စည်းပုံ
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(image: NetworkImage(card.imageUrl), fit: BoxFit.cover),
            ),
          ),
        ),
        // ၂။ အချက်အလက်များ
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "${card.pointsRequired} Pts",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (card.expireDate != null)
                Text(
                  "Expires: ${card.expireDate}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

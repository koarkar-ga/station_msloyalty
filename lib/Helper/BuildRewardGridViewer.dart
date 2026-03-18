import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Helper/RewardDetailDialog.dart';
import 'package:station_msloyalty/Screens/RewardDetailScreen.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
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

      final screenWidth = MediaQuery.of(context).size.width;
      int crossAxisCount = 5;
      if (screenWidth < 600) {
        crossAxisCount = 2;
      } else if (screenWidth < 900) {
        crossAxisCount = 3;
      } else if (screenWidth < 1200) {
        crossAxisCount = 4;
      }

      return GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: screenWidth < 600 ? 0.75 : 0.8,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              if (screenWidth < 750) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RewardDetailScreen(card: cards[index]),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => RewardDetailDialog(card: cards[index]),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: _buildGiftCardItem(cards[index], context),
          );
        },
      );
    },
  );
}

Widget _buildGiftCardItem(GiftCard card, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      color: isDark ? StyleConstants.darkSurface : StyleConstants.lightSurface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        width: 1,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image + Points Badge
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(card.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Points Badge (Glassmorphism)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GlassContainer(
                    opacity: 0.15,
                    blur: 8,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${card.pointsRequired}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2. Info Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? Colors.white : StyleConstants.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  card.description,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.blueGrey[400],
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (card.expireDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "EXPIRES: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(card.expireDate!))}",
                      style: TextStyle(
                        color: isDark ? Colors.redAccent : Colors.red.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/RewardDetailContent.dart';

class RewardDetailScreen extends StatelessWidget {
  final GiftCard card;

  const RewardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? StyleConstants.darkBg : StyleConstants.lightBg,
      appBar: MsAppBar(
        title: card.title,
        showBackButton: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [StyleConstants.darkBg, const Color(0xFF1E293B)]
              : [StyleConstants.lightBg, const Color(0xFFE2E8F0)],
          ),
        ),
        child: RewardDetailContent(
          card: card,
          isMobile: true, // Use mobile-specific stacked layout
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

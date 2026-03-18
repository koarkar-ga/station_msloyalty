import 'package:flutter/material.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Helper/RewardDetailContent.dart';

class RewardDetailDialog extends StatelessWidget {
  final GiftCard card;

  const RewardDetailDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 750,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? StyleConstants.darkBg : StyleConstants.lightSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
              offset: const Offset(0, 10),
              blurRadius: 30,
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: RewardDetailContent(
            card: card,
            isMobile: false, // Dialog layout is usually desktop-style (side-by-side)
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- 1. Image Section (Left Side) ---
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    Image.network(
                      card.imageUrl,
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Points Badge (Glassmorphism)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: GlassContainer(
                        opacity: 0.2,
                        blur: 10,
                        borderRadius: 15,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFFFD700),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${card.pointsRequired} POINTS",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. Content Section (Right Side) ---
              Expanded(
                flex: 1,
                child: Container(
                  color: isDark ? StyleConstants.darkBg : StyleConstants.lightSurface,
                  child: Stack(
                    children: [
                      // Close Button
                      Positioned(
                        right: 15,
                        top: 15,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: GlassContainer(
                            opacity: 0.1,
                            blur: 10,
                            borderRadius: 50,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: isDark ? Colors.white : StyleConstants.lightAccent,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : StyleConstants.lightAccent,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              card.detailDescription ?? card.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.blueGrey[600],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // --- 3. Additional Info ---
                            if (card.agreement != null || card.policies != null) ...[
                              Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  if (card.agreement != null)
                                    _buildInfoChip(
                                      Icons.assignment_turned_in_rounded,
                                      "Agreement",
                                      context,
                                    ),
                                  const SizedBox(width: 12),
                                  if (card.policies != null)
                                    _buildInfoChip(
                                      Icons.verified_user_rounded, 
                                      "Policies",
                                      context,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(
                                card.policies ?? card.agreement ?? "",
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: isDark ? Colors.white54 : Colors.blueGrey[400],
                                ),
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const Spacer(),

                            // --- 4. Action Button ---
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "CLOSE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

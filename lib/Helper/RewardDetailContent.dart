import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Model/GiftCardModel.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class RewardDetailContent extends StatelessWidget {
  final GiftCard card;
  final bool isMobile;
  final VoidCallback onClose;

  const RewardDetailContent({
    super.key,
    required this.card,
    required this.isMobile,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Image Section (at top on mobile)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _buildImageSection(context),
            ),
            // Content Section
            _buildContentSection(context, isDark, isMobile: true),
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // --- 1. Image Section (Left Side) ---
          Expanded(
            flex: 1,
            child: _buildImageSection(context),
          ),

          // --- 2. Content Section (Right Side) ---
          Expanded(
            flex: 1,
            child: _buildContentSection(context, isDark, isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
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
    );
  }

  Widget _buildContentSection(BuildContext context, bool isDark, {required bool isMobile}) {
    return Container(
      color: isDark ? StyleConstants.darkBg : StyleConstants.lightSurface,
      child: Stack(
        children: [
          // Close Button (Only show if not on a full screen or if requested)
          if (!isMobile)
            Positioned(
              right: 15,
              top: 15,
              child: GestureDetector(
                onTap: onClose,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : StyleConstants.lightAccent,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  card.detailDescription ?? card.description,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: isDark ? Colors.white70 : Colors.blueGrey[600],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // --- 2.5 Expire Date ---
                if (card.expireDate != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.red.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "EXPIRES: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(card.expireDate!))}",
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // --- 3. Additional Info ---
                if (card.agreement != null || card.policies != null) ...[
                  Divider(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (card.agreement != null)
                        _buildInfoChip(
                          Icons.assignment_turned_in_rounded,
                          "Agreement",
                          context,
                        ),
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
                    maxLines: isMobile ? 8 : 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (!isMobile) const Spacer(),
                if (isMobile) const SizedBox(height: 32),

                // --- 4. Action Button ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isMobile ? "REDEEM REWARD" : "CLOSE",
                      style: const TextStyle(
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

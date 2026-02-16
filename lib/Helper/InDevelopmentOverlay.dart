import 'dart:ui';

import 'package:flutter/material.dart';

Widget inDevelopmentOverlay() {
  return Positioned.fill(
    child: Stack(
      children: [
        // ၁။ နောက်ခံကို Blur လုပ်မယ်
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ),

        // ၂။ အလယ်က Info Card
        Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction),
                const SizedBox(height: 15),
                const Text(
                  "Development in Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),

                // Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.0, // status.progress ကနေ လာတာ
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

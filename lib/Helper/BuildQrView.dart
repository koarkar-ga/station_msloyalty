import 'package:flutter/material.dart';

Widget buildQRView(AnimationController animationController) {
  return Stack(
    alignment: Alignment.center,
    children: [
      // ၁။ Scan ဖတ်မယ့် ကင်မရာ ဧရိယာ (image_505714 ပုံစံ)
      Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
      ),

      // ၂။ အထက်အောက် ပြေးမယ့် မျဉ်းနီ (Laser Line)
      AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Positioned(
            // Animation value (0 to 1) ကို အမြင့်နဲ့ မြှောက်ပြီး နေရာချမယ်
            top: 25 + (animationController.value * 200),
            child: Opacity(
              opacity: 0.8,
              child: Container(
                width: 230,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

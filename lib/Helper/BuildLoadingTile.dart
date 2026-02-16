import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

Widget buildLoadingTile(String title) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
        ),
        const Expanded(
          child: Center(
            child: SPointLoadingIndicator(), // <--- ငါတို့ဆောက်လိုက်တဲ့ Indicator
          ),
        ),
      ],
    ),
  );
}

class SPointLoadingIndicator extends StatefulWidget {
  const SPointLoadingIndicator({super.key});

  @override
  State<SPointLoadingIndicator> createState() => _SPointLoadingIndicatorState();
}

class _SPointLoadingIndicatorState extends State<SPointLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ၂ စက္ကန့်ကြာတိုင်း တစ်ပတ်လည်မည့် animation
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: List.generate(8, (index) {
                // အစက် ၈ စက်ကို အဝိုင်းပုံစံ စီမယ်
                final angle = index * math.pi / 4;
                return Align(
                  alignment: Alignment(math.cos(angle), math.sin(angle)),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(
                        // တစ်စက်ချင်းစီကို အရောင်မှိန်မှိန်လေးကနေ လင်းလာအောင် လုပ်မယ်
                        (index + 1) / 8,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

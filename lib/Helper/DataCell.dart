import 'package:flutter/material.dart';

Widget buildCardBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15), // နောက်ခံဖျော့ဖျော့
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)), // ဘောင်ကို အရောင်တောက်တောက်
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color, // စာသားကို အရောင်တောက်တောက်
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

Widget dataCell(
  String text,
  double width, {
  Color? cardColor,
  bool showRightBorder = false,
  Color? textColor,
  Alignment alignment = Alignment.centerLeft, // Default က ဘယ်ဘက်ကပ်
  bool isBold = false, // Default က Bold မဟုတ်ဘူး
}) {
  return Container(
    width: width,
    height: 45,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: alignment, // ဒီမှာ alignment ကို သုံးမယ်
    decoration: BoxDecoration(
      border: showRightBorder
          ? Border(right: BorderSide(color: Colors.grey[300]!, width: 0.5))
          : null,
    ),
    child: cardColor != null
        ? buildCardBadge(text, cardColor)
        : Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, // Bold စစ်မယ်
            ),
            overflow: TextOverflow.ellipsis,
          ),
  );
}

import 'package:flutter/material.dart';

Color getSaleTypeColor(String typeName) {
  switch (typeName) {
    case 'Cash Sale':
      return Colors.green;
    case 'Credit Sale':
      return Colors.orange;
    case 'Donation':
      return Colors.purple;
    case 'Transfer':
      return Colors.blue;
    case 'ePayment':
      return Colors.cyan;
    case 'Mobile':
      return Colors.teal;
    case 'Pump Test':
      return Colors.redAccent;
    case 'Card Sale':
      return Colors.lightBlue;
    case 'Office Use':
      return Colors.brown;
    case 'Offline Sale(System Off Sale)':
      return Colors.grey;
    case 'Cooperate Sale':
      return Colors.tealAccent;
    default:
      return Colors.black87;
  }
}

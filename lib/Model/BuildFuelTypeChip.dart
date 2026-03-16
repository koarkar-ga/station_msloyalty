import 'package:flutter/material.dart';

Color getFuelColor(String fuelName) {
  switch (fuelName.trim()) {
    case 'Gasoline':
      return Colors.orange;
    case 'Diesel':
    case 'Diesel WS':
      return Colors.grey.shade600;
    case 'Octane (92)Ron':
      return Colors.yellow.shade900;
    case 'Octane (95)Ron':
      return Colors.red.shade600;
    case 'Premium Diesel':
    case 'Premium WS':
      return Colors.blue.shade700;
    case 'Octane 97':
      return Colors.purple.shade600;
    default:
      return Colors.blueGrey;
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool _isApiOnline = false;
bool _isEhoUpdate = false;

int _ehoRemainingToSendCount = 0;

AppBar CustomizeAppBar() {
  return AppBar(
    title: Row(
      children: [
        Image.asset('assets/images/moonsun_logo.png', height: 30),
        const SizedBox(width: 10),
        const Text("Station MS Loyalty Dashboard"),
      ],
    ),
    backgroundColor: Colors.blueGrey.shade900,
    foregroundColor: Colors.white,
    actions: [
      const SizedBox(width: 20),
      _buildStatusIndicator(),

      const SizedBox(width: 10),
      // Sidebar ကို ဖွင့်မည့် ခလုတ်
      Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.more_time),
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
        ),
      ),
      const SizedBox(width: 20),
      Text("ယနေ့ရက်စွဲ: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}"),
      const SizedBox(width: 20),
    ],
  );
}

Widget _buildStatusIndicator() {
  return Row(
    children: [
      Icon(Icons.circle, size: 12, color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent),
      const SizedBox(width: 8),
      Text(
        _isEhoUpdate
            ? "EHO ONLINE : $_ehoRemainingToSendCount"
            : "EHO OFFLINE : $_ehoRemainingToSendCount",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      const SizedBox(width: 20),
      Divider(),
      Icon(Icons.circle, size: 12, color: _isApiOnline ? Colors.greenAccent : Colors.redAccent),
      const SizedBox(width: 8),
      Text(
        _isApiOnline ? "API ONLINE" : "API OFFLINE",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isApiOnline ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      const SizedBox(width: 20),
    ],
  );
}

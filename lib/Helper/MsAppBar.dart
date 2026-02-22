import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Services/ConnectionStatus.dart';

class MsAppBar extends StatefulWidget {
  final String title;
  const MsAppBar({super.key, this.title = 'Dashboard'});

  @override
  State<MsAppBar> createState() => _MsAppBarState();
}

class _MsAppBarState extends State<MsAppBar> {
  // API Configurations
  // Windows Desktop တွင် local run ထားသော Node.js အတွက် localhost:3000 သုံးနိုင်သည်
  final String apiHealthUrl = "${AppConfig.apiUrl}/api/health";
  final String apiUrl = "${AppConfig.apiUrl}/api/sales/recent";
  final String apiEhoSendCount = "${AppConfig.apiUrl}/api/eho/send-count";

  bool _isApiOnline = false;
  bool _isEhoUpdate = false;
  Timer? _timer;
  int _ehoRemainingToSendCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkApiConnection();
      _ehoRemainingToSend();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  Future<bool> checkApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.apiHealthUrl))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        print(response.body);
        if (mounted) {
          setState(() {
            _isApiOnline = true;
          });
        }
      }
      print("API Status: ${response.statusCode}");
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApiOnline = false;
        });
      }
      print(e.toString());
    }
    return _isApiOnline;
  }

  // EHO Reaming to send count
  // API Connection အခြေအနေကို စစ်ဆေးခြင်း
  Future<void> _ehoRemainingToSend() async {
    try {
      final response = await http
          .get(Uri.parse(apiEhoSendCount))
          .timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _ehoRemainingToSendCount = data[0]['COUNT'];
            _ehoRemainingToSendCount < 100 ? _isEhoUpdate = true : _isEhoUpdate = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _ehoRemainingToSendCount = json.decode(response.body)[''];
            _ehoRemainingToSendCount < 100 ? _isEhoUpdate = true : _isEhoUpdate = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ehoRemainingToSendCount = 0;
          _isEhoUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return customizeAppBar(context: context, title: widget.title);
  }

  Widget customizeAppBar({
    String title = "Station MS Loyalty > Dashboard",
    required BuildContext context,
  }) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset('assets/images/moonsun_logo.png', height: 30),
          const SizedBox(width: 10),
          Text(title),
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
        Column(
          children: [
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("ယနေ့ရက်စွဲ: ${DateFormat('dd-MM-yyyy').format(now)}"),
                    Text("ယနေ့အချိန်: ${DateFormat('hh:mm aa').format(now)}"),
                  ],
                );
              },
            ),
          ],
        ),
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
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Services/ConnectionStatus.dart';
import 'package:station_msloyalty/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingStatus = "Checking connections...";
  bool _isApiOnline = false;

  @override
  void initState() {
    super.initState();
    initializeApp(context);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // ပိတ်လို့မရအောင် လုပ်ထားမယ်
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text("Connection Failed"),
          ],
        ),
        content: Text(message), // ဒီမှာ "Supabase..." လား "API..." လားဆိုတာ ပြလိမ့်မယ်
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Retry ပြန်လုပ်ခိုင်းမယ်
              await initializeApp(context);
            },
            child: const Text("Retry"),
          ),
          TextButton(
            onPressed: () => exit(0), // App ကို ပိတ်ပစ်လိုက်မယ်
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  // Supabase စစ်ဆေးခြင်း
  Future<bool> checkSupabaseConnection() async {
    try {
      // ရိုးရိုးရှင်းရှင်း table တစ်ခုကို ခဏလှမ်းခေါ်ကြည့်တာမျိုးနဲ့ စစ်လို့ရတယ်
      await Supabase.instance.client.from('stations').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> initializeApp(BuildContext context) async {
    try {
      // ၁။ Supabase Connection စစ်မယ်
      bool isSupabaseOk = await checkSupabaseConnection();
      if (!isSupabaseOk) throw "Cloud Server Connection Failed!";

      // ၂။ API Connection စစ်မယ်
      bool isApiOk = await checkApiConnection();
      if (!isApiOk) throw "API Server Connection Failed!";

      // ၃။ API ကနေ Sale Type / Fuel Type တွေယူပြီး Local မှာ သိမ်းမယ်
      await syncSaleTypes();
      await syncFuelTypes();

      // အကုန်အဆင်ပြေရင် Login ကို သွားမယ်
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      // Error တက်ရင် Alert Box ပြမယ်
      _showErrorDialog(context, e.toString());
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100), // သားကြီးတို့ ဆိုင် Logo ထည့်ရန်
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_loadingStatus, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

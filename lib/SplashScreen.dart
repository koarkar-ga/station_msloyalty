import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/SetupScreen.dart';
import 'package:station_msloyalty/login_page.dart';
import 'package:station_msloyalty/Services/UpdateService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingStatus = "Checking connections...";
  bool _isApiOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeApp(context);
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 12),
            Text("Connection Failed", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SetupScreen()),
              );
            },
            child: const Text(
              "Reconfig",
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await initializeApp(context);
            },
            child: const Text(
              "Retry",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          TextButton(
            onPressed: () => exit(0),
            child: const Text(
              "Exit",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> checkSupabaseConnection() async {
    try {
      await Supabase.instance.client
          .from('stations')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> initializeApp(BuildContext context) async {
    try {
      if (!AppConfig.configExists) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
        return;
      }

      if (mounted) setState(() => _loadingStatus = "Connecting to Cloud...");
      bool isSupabaseOk = await checkSupabaseConnection();
      if (!isSupabaseOk) throw "Cloud Server Connection Failed!";

      if (mounted) {
        setState(() => _loadingStatus = "Connecting to Local API...");
      }
      bool isApiOk = await checkApiConnection();
      if (!isApiOk) throw "API Server Connection Failed!";

      if (mounted) setState(() => _loadingStatus = "Syncing Local Catalog...");
      try {
        await syncSaleTypes().timeout(const Duration(seconds: 5));
        await syncFuelTypes().timeout(const Duration(seconds: 5));
      } catch (e) {}

      if (mounted) setState(() => _loadingStatus = "Checking for Updates...");
      if (!mounted) return;
      await UpdateService().checkForUpdates(context);

      if (mounted) setState(() => _loadingStatus = "Launching Station App...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, e.toString());
    }
  }

  Future<bool> checkApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.apiHealthUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        if (mounted) setState(() => _isApiOnline = true);
        return true;
      } else {
        // statusCode 500 etc.
        throw "API Server reached but returned status ${response.statusCode}. Please check Database settings.";
      }
    } catch (e) {
      if (mounted) setState(() => _isApiOnline = false);
      if (e.toString().contains('TimeoutException')) {
        throw "API Server connection timed out. Is the server running?";
      } else if (e.toString().contains('Connection refused')) {
        throw "API Server connection refused. Please check the URL/Port in Setup.";
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'logo',
                child: Image.asset(
                  "assets/images/moonsun_logo.png",
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  color: const Color(0xFF38BDF8),
                  minHeight: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _loadingStatus.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:station_msloyalty/CollectPointScreen.dart';
import 'package:station_msloyalty/ReportScreen.dart';
import 'package:station_msloyalty/RewardPointScreen.dart';
import 'package:station_msloyalty/SettingScreen.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/DashboardScreen.dart';
import 'package:station_msloyalty/LoyaltyReportScreen.dart';
import 'package:station_msloyalty/login_page.dart';
import 'package:station_msloyalty/Services/ActivityService.dart';

class AppLauncherScreen extends StatelessWidget {
  const AppLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("Moonsun - ${AppConfig.stationName}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              // Log Login Activity
              await ActivityService.logActivity(
                actionType: 'login',
                description: 'User ${AppConfig.currentUserName} logged in at ${AppConfig.stationName}',
              );
              
              AppConfig.currentUserLevel = 11;
              AppConfig.currentUserId = null;
              AppConfig.currentUserName = null;
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.count(
            shrinkWrap: true, // Grid ကို အလယ်မှာ စုပေးဖို့
            crossAxisCount: 6, // တစ်တန်းမှာ ၄ ခုပြမယ်
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildMenuButton(
                context,
                icon: Icons.dashboard_rounded,
                label: "Dashboard",
                color: Colors.blue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                ),
              ),
              // _buildMenuButton(
              //   context,
              //   icon: Icons.local_gas_station,
              //   label: "Sale Entry",
              //   color: Colors.green,
              //   onTap: () => Navigator.of(
              //     context,
              //   ).push(MaterialPageRoute(builder: (context) => const SaleEntryScreen())),
              // ),

              // ... GridView ရဲ့ children ထဲမှာ ဒါလေးတွေ ထပ်ဖြည့်ပါ ...
              _buildMenuButton(
                context,
                icon: Icons.add_chart_rounded, // Point စုတဲ့ Icon
                label: "Collect Point",
                color: Colors.purple,
                onTap: () {
                  // Collect Point Screen ဆီသွားမည့် Logic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CollectPointScreen(),
                    ),
                  );
                },
              ),

              _buildMenuButton(
                context,
                icon: Icons.card_giftcard_rounded, // Reward/Gift Icon
                label: "Reward Point",
                color: Colors.pink,
                onTap: () {
                  // Reward Point Screen ဆီသွားမည့် Logic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RewardPointScreen(),
                    ),
                  );
                },
              ),
              _buildMenuButton(
                context,
                icon: Icons.assessment,
                label: "Reports",
                color: Colors.orange,
                onTap: () {
                  if (AppConfig.currentUserLevel == 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  } else {
                    _showNoPermissionDialog(context);
                  }
                },
              ),
              _buildMenuButton(
                context,
                icon: Icons.pie_chart_rounded, // Loyalty Reports Icon
                label: "Loyalty Reports",
                color: Colors.teal,
                onTap: () {
                  if (AppConfig.currentUserLevel == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoyaltyReportScreen(),
                      ),
                    );
                  } else {
                    _showNoPermissionDialog(context);
                  }
                },
              ),
              _buildMenuButton(
                context,
                icon: Icons.settings,
                label: "Settings",
                color: Colors.grey,
                onTap: () {
                  if (AppConfig.currentUserLevel == 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  } else {
                    _showNoPermissionDialog(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: const Text("You don't have permission to access this screen. Please contact your administrator."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ခလုတ်ဒီဇိုင်းအတွက် Helper Function
  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon လေးကို ဝိုင်းဝိုင်းလေးနဲ့ လှအောင်လုပ်ခြင်း
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 10),
          // အောက်က Label စာသား
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

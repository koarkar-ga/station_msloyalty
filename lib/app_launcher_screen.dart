import 'package:flutter/material.dart';
import 'package:station_msloyalty/CollectPointScreen.dart';
import 'package:station_msloyalty/ReportScreen.dart';
import 'package:station_msloyalty/RewardPointScreen.dart';
import 'package:station_msloyalty/SettingScreen.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/DashboardScreen.dart';
import 'package:station_msloyalty/LoyaltyReportScreen.dart';
import 'package:station_msloyalty/login_page.dart';
import 'package:station_msloyalty/Screens/StockReportScreen.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 5;
          if (constraints.maxWidth < 500) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 800) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 1100) {
            crossAxisCount = 4;
          }

          double spacing = constraints.maxWidth < 600 ? 16.0 : 32.0;

          return Center(
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                children: [
                  if (AppConfig.permissions['Dashboard'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.dashboard_rounded,
                      label: "Dashboard",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => DashboardScreen()),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Collect Point'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.add_chart_rounded,
                      label: "Collect Point",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CollectPointScreen(),
                          ),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Reward Point'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.card_giftcard_rounded,
                      label: "Reward Point",
                      color: Colors.pink,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RewardPointScreen(),
                          ),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Reports'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.assessment,
                      label: "Reports",
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Loyalty Reports'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.pie_chart_rounded,
                      label: "Loyalty Reports",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoyaltyReportScreen(),
                          ),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Reports'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.inventory_2_rounded,
                      label: "Stock Report",
                      color: Colors.brown,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StockReportScreen(),
                          ),
                        );
                      },
                    ),
                  if (AppConfig.permissions['Settings'] == true || AppConfig.currentUserLevel == 1)
                    _buildMenuButton(
                      context,
                      icon: Icons.settings,
                      label: "Settings",
                      color: Colors.grey,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
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

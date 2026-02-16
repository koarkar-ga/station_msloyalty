import 'package:flutter/material.dart';
import 'package:station_msloyalty/CollectPointScreen.dart';
import 'package:station_msloyalty/ReportScreen.dart';
import 'package:station_msloyalty/RewardPointScreen.dart';
import 'package:station_msloyalty/SaleEntryScreen.dart';
import 'package:station_msloyalty/SettingScreen.dart';
import 'package:station_msloyalty/DashboardScreen.dart';

class AppLauncherScreen extends StatelessWidget {
  const AppLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("POS Loyalty System"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
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
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => DashboardScreen())),
              ),
              _buildMenuButton(
                context,
                icon: Icons.local_gas_station,
                label: "Sale Entry",
                color: Colors.green,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => const SaleEntryScreen())),
              ),

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
                    MaterialPageRoute(builder: (context) => const CollectPointScreen()),
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
                    MaterialPageRoute(builder: (context) => RewardPointScreen()),
                  );
                },
              ),
              _buildMenuButton(
                context,
                icon: Icons.assessment,
                label: "Reports",
                color: Colors.orange,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => const ReportsScreen())),
              ),
              _buildMenuButton(
                context,
                icon: Icons.settings,
                label: "Settings",
                color: Colors.grey,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ),
            ],
          ),
        ),
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 10),
          // အောက်က Label စာသား
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

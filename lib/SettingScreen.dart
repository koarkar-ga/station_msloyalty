import 'package:flutter/material.dart';
import 'package:station_msloyalty/Helper/InDevelopmentOverlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Settings")),
      body: Stack(
        children: [
          Row(
            children: [
              // ၁။ ဘယ်ဘက်ခြမ်း - Navigation Rail (Settings Categories)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.local_gas_station_outlined),
                    selectedIcon: Icon(Icons.local_gas_station),
                    label: Text('Fuel Prices'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.print_outlined),
                    selectedIcon: Icon(Icons.print),
                    label: Text('Printer'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Account'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),

              // ၂။ ညာဘက်ခြမ်း - Settings Content
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildFuelPriceSettings(),
                    _buildPrinterSettings(),
                    _buildAccountSettings(),
                  ],
                ),
              ),
            ],
          ),
          inDevelopmentOverlay(),
        ],
      ),
    );
  }

  // ဆီဈေးနှုန်းပြင်ရန် Setting
  Widget _buildFuelPriceSettings() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fuel Price Management",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _priceEditTile("92 Ron", "2,500 MMK"),
          _priceEditTile("95 Ron", "2,800 MMK"),
          _priceEditTile("Premium Diesel", "3,100 MMK"),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () {}, child: const Text("Update All Prices")),
        ],
      ),
    );
  }

  Widget _priceEditTile(String label, String currentPrice) {
    return ListTile(
      title: Text(label),
      subtitle: Text("Current: $currentPrice"),
      trailing: SizedBox(
        width: 150,
        child: TextField(
          decoration: const InputDecoration(hintText: "New Price", isDense: true),
          keyboardType: TextInputType.number,
        ),
      ),
    );
  }

  // Printer ချိတ်ရန် Setting
  Widget _buildPrinterSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.print, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("No Printer Connected"),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: const Text("Scan for Printers")),
        ],
      ),
    );
  }

  // Account Setting
  Widget _buildAccountSettings() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.admin_panel_settings, size: 50)),
          const SizedBox(height: 20),
          const ListTile(title: Text("Username"), subtitle: Text("Admin_Station_01")),
          const ListTile(title: Text("Role"), subtitle: Text("Manager")),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout from System"),
          ),
        ],
      ),
    );
  }
}

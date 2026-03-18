import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Model/AppSettings.dart';
import 'package:station_msloyalty/Helper/InDevelopmentOverlay.dart';
import 'package:station_msloyalty/Services/FuelPriceService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;
  bool _useCameraScanner = false;
  
  // Fuel Price Data
  Map<String, dynamic>? _livePrices;
  bool _isPricesLoading = false;

  // Server Config Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _dbController = TextEditingController();
  final _apiController = TextEditingController();
  bool _isSavingConfig = false;

  // HO Config Mode State
  String _configMode = 'Station'; // 'HO' or 'Station'
  List<Map<String, dynamic>> _stations = [];
  String? _selectedStationId;
  bool _isLoadingStations = false;
  

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppConfig.isar.appSettings.where().findFirst();
    setState(() {
      _useCameraScanner = settings?.useCameraScanner ?? false;
      _isPricesLoading = true;
      
      // Initialize Server Config Controllers
      _nameController.text = AppConfig.stationName;
      _idController.text = AppConfig.stationId;
      _hostController.text = AppConfig.host;
      _userController.text = AppConfig.username;
      _passController.text = AppConfig.password;
      _dbController.text = AppConfig.database;
      _apiController.text = AppConfig.apiUrl;
    });

    try {
      final fuelService = FuelPriceService();
      final prices = await fuelService.fetchLatestPrices();
      if (mounted) {
        setState(() {
          _livePrices = prices;
          _isPricesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPricesLoading = false);
      }
    }

    // Fetch stations if user is Admin
    if (AppConfig.currentUserLevel == 1) {
      _fetchStations();
    }
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoadingStations = true);
    try {
      final data = await Supabase.instance.client
          .from('stations')
          .select('station_id, name')
          .order('name');
      
      if (mounted) {
        setState(() {
          _stations = List<Map<String, dynamic>>.from(data);
          _isLoadingStations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStations = false);
      }
    }
  }

  void _showStationSearchDialog() {
    String searchQuery = "";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Station"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search by Name or ID...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setDialogState(() => searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _stations.where((s) {
                      final name = s['name']?.toString().toLowerCase() ?? "";
                      final id = s['station_id']?.toString().toLowerCase() ?? "";
                      return name.contains(searchQuery) || id.contains(searchQuery);
                    }).length,
                    itemBuilder: (context, index) {
                      final filtered = _stations.where((s) {
                        final name = s['name']?.toString().toLowerCase() ?? "";
                        final id = s['station_id']?.toString().toLowerCase() ?? "";
                        return name.contains(searchQuery) || id.contains(searchQuery);
                      }).toList();
                      final s = filtered[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.ev_station, size: 20)),
                        title: Text(s['name'] ?? ""),
                        subtitle: Text("ID: ${s['station_id']}"),
                        onTap: () {
                          _handleStationSelect(s['station_id']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    _dbController.dispose();
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _toggleCameraScanner(bool value) async {
    final settings =
        await AppConfig.isar.appSettings.where().findFirst() ?? AppSettings();
    settings.useCameraScanner = value;
    await AppConfig.isar.writeTxn(() async {
      await AppConfig.isar.appSettings.put(settings);
    });
    setState(() {
      _useCameraScanner = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;

    // Define categories
    final List<Map<String, dynamic>> allCategories = [
      {
        'label': 'Scanner',
        'icon': Icons.qr_code_scanner_outlined,
        'selectedIcon': Icons.qr_code_scanner,
        'body': _buildScannerSettings(),
      },
      {
        'label': 'Fuel Prices',
        'icon': Icons.local_gas_station_outlined,
        'selectedIcon': Icons.local_gas_station,
        'body': _buildFuelPriceSettings(),
      },
      {
        'label': 'Printer',
        'icon': Icons.print_outlined,
        'selectedIcon': Icons.print,
        'body': Stack(
          children: [_buildPrinterSettings(), inDevelopmentOverlay()],
        ),
      },
      {
        'label': 'Account',
        'icon': Icons.person_outline,
        'selectedIcon': Icons.person,
        'body': _buildAccountSettings(),
      },
      {
        'label': 'Server Config',
        'icon': Icons.settings_ethernet_outlined,
        'selectedIcon': Icons.settings_ethernet,
        'body': _buildServerSettings(),
      },
    ];

    // Filter for mobile
    final categories = isMobile
        ? allCategories.where((c) => c['label'] != 'Scanner').toList()
        : allCategories;

    // Ensure _selectedIndex is within range
    if (_selectedIndex >= categories.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("App Settings")),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: categories.map((cat) {
                return BottomNavigationBarItem(
                  icon: Icon(cat['icon']),
                  activeIcon: Icon(cat['selectedIcon']),
                  label: cat['label'],
                );
              }).toList(),
            )
          : null,
      body: isMobile
          ? IndexedStack(
              index: _selectedIndex,
              children: categories.map<Widget>((cat) => cat['body'] as Widget).toList(),
            )
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: categories.map((cat) {
                    return NavigationRailDestination(
                      icon: Icon(cat['icon']),
                      selectedIcon: Icon(cat['selectedIcon']),
                      label: Text(cat['label']),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: categories.map<Widget>((cat) => cat['body'] as Widget).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  // Scanner Setting (New)
  Widget _buildScannerSettings() {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scanner Configuration",
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Choose between using an external hardware scanner (keyboard input) or the built-in PC Camera.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.camera_alt),
            title: const Text("Use PC Camera for QR Scan"),
            subtitle: const Text(
              "Enable this to use the webcam instead of an external scanner.",
            ),
            trailing: Switch(
              value: _useCameraScanner,
              onChanged: _toggleCameraScanner,
              activeThumbColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // ဆီဈေးနှုန်းပြင်ရန် Setting
  Widget _buildFuelPriceSettings() {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today Price List",
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _isPricesLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : Column(
                children: [
                  _priceDisplayTile("92 Ron", "${_livePrices?['octane_92'] ?? '---'} MMK", Colors.orange),
                  _priceDisplayTile("95 Ron", "${_livePrices?['octane_95'] ?? '---'} MMK", Colors.red),
                  _priceDisplayTile("Diesel", "${_livePrices?['diesel'] ?? '---'} MMK", Colors.green),
                  _priceDisplayTile("Premium Diesel", "${_livePrices?['premium_diesel'] ?? '---'} MMK", Colors.blue),
                ],
              ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _priceDisplayTile(String label, String currentPrice, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        currentPrice,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      leading: Icon(Icons.local_gas_station, color: color),
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
          ElevatedButton(
            onPressed: () {},
            child: const Text("Scan for Printers"),
          ),
        ],
      ),
    );
  }

  // Account Setting
  Widget _buildAccountSettings() {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: isMobile ? 40 : 50,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(
              Icons.admin_panel_settings, 
              size: isMobile ? 40 : 50,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text("Username"),
            subtitle: Text(AppConfig.currentUserName ?? "Unknown User"),
          ),
          ListTile(
            title: const Text("Role Level"), 
            subtitle: Text("Level ${AppConfig.currentUserLevel}"),
          ),
          ListTile(
            title: const Text("Station Name"),
            subtitle: Text(AppConfig.stationName),
          ),
          ListTile(
            title: const Text("Station Code"),
            subtitle: Text(AppConfig.stationId),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Logout from System"),
            ),
          ),
        ],
      ),
    );
  }

  // Server Config Setting (New)
  Widget _buildServerSettings() {
    final isMobile = MediaQuery.of(context).size.width < 750;
    final isAdmin = AppConfig.currentUserLevel == 1;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Server Configuration",
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Update your station details, database connection, and API settings here.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),

          if (isAdmin) ...[
            Text("Configuration Mode", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'HO', label: Text('HO Config'), icon: Icon(Icons.business)),
                ButtonSegment(value: 'Station', label: Text('Station Config'), icon: Icon(Icons.settings_input_component)),
              ],
              selected: {_configMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _configMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            if (_configMode == 'HO') ...[
              Text("Target Station", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
              const SizedBox(height: 12),
              InkWell(
                onTap: _showStationSearchDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.blueGrey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedStationId == null 
                            ? "Tap to search & select station..." 
                            : "${_nameController.text} (${_selectedStationId})",
                          style: TextStyle(
                            color: _selectedStationId == null ? Colors.grey : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (_isLoadingStations)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              const SizedBox(height: 30),
            ],
          ],

          Text("Station Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
          const Divider(),
          _buildSettingField(_nameController, "Station Name", Icons.store, readOnly: _configMode == 'HO'),
          _buildSettingField(_idController, "Station ID", Icons.badge, readOnly: _configMode == 'HO'),
          
          if (_configMode != 'HO') ...[
            const SizedBox(height: 24),
            Text("Database Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const Divider(),
            _buildSettingField(_hostController, "Server Host", Icons.cloud_queue),
            _buildSettingField(_dbController, "Database Name", Icons.storage),
            _buildSettingField(_userController, "Username", Icons.person_outline),
            _buildSettingField(_passController, "Password", Icons.lock_outline, isPassword: true),
            
            const SizedBox(height: 24),
            Text("API Connection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const Divider(),
            _buildSettingField(_apiController, "Local API URL", Icons.link),
          ],
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingConfig ? null : _handleSaveConfig,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSavingConfig 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Apply & Save Configuration"),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _handleStationSelect(String stationId) async {
    setState(() {
      _selectedStationId = stationId;
      _isLoadingStations = true;
    });

    try {
      // 1. Get basic station info (Name)
      final station = _stations.firstWhere((s) => s['station_id'] == stationId);
      _nameController.text = station['name'] ?? '';
      _idController.text = station['station_id'] ?? '';
      _dbController.text = station['station_id'] ?? ''; // DB Name becomes Station ID

      // 2. Fetch connection details from the auth table for 'ALL' stations
      // This is the central HO server config we set up in the previous step.
      final hoConfig = await Supabase.instance.client
          .from('auth')
          .select('*')
          .eq('station_code', 'ALL')
          .maybeSingle();

      if (hoConfig != null) {
        _hostController.text = hoConfig['db_host'] ?? _hostController.text;
        _userController.text = hoConfig['db_user'] ?? _userController.text;
        _passController.text = hoConfig['db_pass'] ?? _passController.text;
        _apiController.text = hoConfig['api_url'] ?? _apiController.text;
      }
    } catch (e) {
      debugPrint("Error auto-fetching station config: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStations = false);
    }
  }

  Widget _buildSettingField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Future<void> _handleSaveConfig() async {
    setState(() => _isSavingConfig = true);
    try {
      await AppConfig.saveConfig(
        name: _nameController.text,
        id: _idController.text,
        dbHost: _hostController.text,
        dbUser: _userController.text,
        dbPass: _passController.text,
        dbName: _dbController.text,
        api: _apiController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server configuration updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update config: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }
}

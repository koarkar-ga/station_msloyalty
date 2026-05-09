import 'package:flutter/material.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/SplashScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
    final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController(text: "MOONSUN");
  final _idController = TextEditingController(text: "M001");
  final _hostController = TextEditingController(text: "localhost");
  final _userController = TextEditingController(text: "sa");
  final _passController = TextEditingController(text: "infosys2011iss@");
  final _dbController = TextEditingController(text: "M001");
    final _apiController = TextEditingController(text: "http://localhost:3000");
  final _portController = TextEditingController(text: "1433");
  final _hoPasswordController = TextEditingController();

  bool _isSaving = false;
  String _setupMode = 'none'; // 'none', 'ho', 'station'
  List<Map<String, dynamic>> _stations = [];
  bool _isLoadingStations = false;
  String? _selectedStationName;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await AppConfig.saveConfig(
        name: _nameController.text,
        id: _idController.text,
        dbHost: _hostController.text,
        dbUser: _userController.text,
        dbPass: _passController.text,
        dbName: _dbController.text,
        api: _apiController.text,
        dbPort: _portController.text,
        hoConfig: false,
      );
      
      // Validation step
      await AppConfig.verifyPersistence();

      _finalizeSetup();
    } catch (e) {
      _showError("Error saving config: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    _portController.dispose();
    _hoPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoadingStations = true);
    try {
      final response = await supabase
          .from('stations')
          .select('name, station_id')
          .order('name');
      setState(() {
        _stations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    } finally {
      setState(() => _isLoadingStations = false);
    }
  }

  Future<void> _handleHOSetup() async {
    setState(() => _isSaving = true);
    try {
      // 1. Verify Password against Cloud DB system_settings
      final pwdResponse = await supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'ho_config_password')
          .maybeSingle();
      
      final authorizedPwd = pwdResponse?['value'] ?? 'msloyalty@ho';

      if (_hoPasswordController.text != authorizedPwd) {
        throw "Incorrect HO Configuration Password.";
      }

      // 2. Fetch Server Config
      final config = await supabase
          .from('auth')
          .select('db_host, db_user, db_pass, db_name, api_url, db_port')
          .eq('station_code', 'ALL')
          .limit(1)
          .maybeSingle();

      if (config == null) {
        throw "HO Configuration not found in Cloud Database.";
      }

      await AppConfig.saveConfig(
        name: "ALL STATION (HO)",
        id: "ALL",
        dbHost: config['db_host'] ?? 'localhost',
        dbUser: config['db_user'] ?? 'sa',
        dbPass: config['db_pass'] ?? '',
        dbName: config['db_name'] ?? 'HO',
        api: config['api_url'] ?? 'http://localhost:3000',
        dbPort: config['db_port']?.toString() ?? '1433',
        hoConfig: true,
      );

      _finalizeSetup();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchPredefinedConfig(String stationId) async {
    setState(() => _isLoadingStations = true);
    try {
      final config = await supabase
          .from('auth')
          .select('db_host, db_user, db_pass, db_name, api_url, db_port')
          .eq('station_code', stationId)
          .limit(1)
          .maybeSingle();

      if (config != null) {
        setState(() {
          _hostController.text = config['db_host'] ?? _hostController.text;
          _userController.text = config['db_user'] ?? _userController.text;
          _passController.text = config['db_pass'] ?? _passController.text;
          _dbController.text = config['db_name'] ?? _dbController.text;
          _apiController.text = config['api_url'] ?? _apiController.text;
          _portController.text = config['db_port']?.toString() ?? _portController.text;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pre-defined configuration applied."), backgroundColor: Colors.blue),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching predefined config: $e");
    } finally {
      setState(() => _isLoadingStations = false);
    }
  }

  void _finalizeSetup() async {
    bool isVerified = await AppConfig.verifyPersistence();
    if (mounted) {
      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Setup Complete!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
      } else {
        _showError("Verification Failed: Persistence Error.");
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("App Configuration"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _setupMode != 'none' 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _setupMode = 'none'))
          : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_setupMode == 'none') return _buildModeSelection();
    if (_setupMode == 'ho') return _buildHOConfig();
    return _buildStationConfig();
  }

  Widget _buildModeSelection() {
    return Column(
      children: [
        const Icon(Icons.settings_suggest, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 24),
        const Text(
          "Setup Application",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          "Choose how you want to configure this device",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 48),
        _buildModeButton(
          title: "HO Config",
          subtitle: "Auto-setup for Head Office viewing",
          icon: Icons.admin_panel_settings,
          color: Colors.purpleAccent,
          onTap: () => setState(() => _setupMode = 'ho'),
        ),
        const SizedBox(height: 20),
        _buildModeButton(
          title: "Station Config",
          subtitle: "Manual setup for specific Station",
          icon: Icons.ev_station,
          color: Colors.blueAccent,
          onTap: () => setState(() => _setupMode = 'station'),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildHOConfig() {
    return Column(
      children: [
        const Text("HO Configuration Setup", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text("Enter the configuration password provided by your IT department.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _buildTextField(_hoPasswordController, "HO Config Password", Icons.lock, isPassword: true),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleHOSetup,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Verify & Auto Setup"),
          ),
        ),
      ],
    );
  }

  Widget _buildStationConfig() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Station Configuration", style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          if (_isLoadingStations)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            ),
          DropdownButtonFormField<String>(
            value: _selectedStationName,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Select Station",
              labelStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store, color: Colors.white54),
            ),
            items: _stations.map((s) => DropdownMenuItem<String>(
              value: s['name'] as String,
              child: Text(s['name'] as String),
            )).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStationName = val;
                _nameController.text = val!;
                _idController.text = _stations.firstWhere((s) => s['name'] == val)['station_id']!;
              });
              _fetchPredefinedConfig(_idController.text);
            },
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(_idController, "Station ID", Icons.badge, readOnly: true),
          const SizedBox(height: 16),
          _buildTextField(_hostController, "Database Hostname", Icons.cloud_queue),
          _buildTextField(_dbController, "Database Name", Icons.storage),
          _buildTextField(_userController, "DB Username", Icons.person),
          _buildTextField(_portController, "DB Port", Icons.settings_input_component),
          _buildTextField(_passController, "DB Password", Icons.lock, isPassword: true),
          _buildTextField(_apiController, "Local API URL", Icons.link),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save & Start"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        readOnly: readOnly,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.white.withOpacity(0.05) : null,
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }
}

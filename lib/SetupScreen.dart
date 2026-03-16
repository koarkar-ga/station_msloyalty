import 'package:flutter/material.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/SplashScreen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: "MOONSUN");
  final _idController = TextEditingController(text: "M001");
  final _hostController = TextEditingController(text: "localhost");
  final _userController = TextEditingController(text: "sa");
  final _passController = TextEditingController(text: "infosys2011iss@");
  final _dbController = TextEditingController(text: "M001");
  final _apiController = TextEditingController(text: "http://localhost:3000");

  bool _isSaving = false;

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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuration saved successfully!")),
        );
        // Navigate to SplashScreen to re-initialize
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving config: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Station Application Setup"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Initial Configuration",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please fill in the details to generate Config.ini",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      "Station Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Divider(),
                    _buildTextField(
                      _nameController,
                      "Station Name",
                      Icons.store,
                    ),
                    _buildTextField(_idController, "Station ID", Icons.badge),

                    const SizedBox(height: 24),
                    const Text(
                      "Database Settings",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Divider(),
                    _buildTextField(
                      _hostController,
                      "Server / Host",
                      Icons.cloud_queue,
                    ),
                    _buildTextField(
                      _dbController,
                      "Database Name",
                      Icons.storage,
                    ),
                    _buildTextField(_userController, "Username", Icons.person),
                    _buildTextField(
                      _passController,
                      "Password",
                      Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "API Settings",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Divider(),
                    _buildTextField(
                      _apiController,
                      "Local API URL",
                      Icons.link,
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save & Start Application"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Required";
          }
          return null;
        },
      ),
    );
  }
}

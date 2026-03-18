import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Services/AuthService.dart';
import 'package:station_msloyalty/Services/ActivityService.dart';
import 'package:station_msloyalty/app_launcher_screen.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      final data = await authService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (data!['status'] == 'success') {
        final userStationCode = data['station_code'] as String?;
        bool canLogin = userStationCode == null || userStationCode == 'ALL' || userStationCode == AppConfig.stationId;
        if (!canLogin) {
          setState(() => _isLoading = false);
          _showError('Access Denied', 'သင်သည် ဤဆိုင် (${AppConfig.stationId}) တွင် Login ဝင်ရန် ခွင့်ပြုချက်မရှိပါ။');
          return;
        }
        AppConfig.currentUserLevel = data['userlevel'] ?? 11;
        AppConfig.currentUserId = data['id'];
        AppConfig.currentUserName = data['fullname'] ?? _usernameController.text.trim();
        
        // Log Login Activity
        await ActivityService.logActivity(
          actionType: 'login',
          description: 'User ${AppConfig.currentUserName} logged in at ${AppConfig.stationName}',
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppLauncherScreen()),
          (route) => false,
        );
      } else {
        _showError('Login Failed', data['message']);
      }
    } catch (e) {
      _showError('Error', 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.blueAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const MsAppBar(title: "Moon Sun Station"),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle patterns or background images can be added here
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = MediaQuery.of(context).size.width < 600;
                    return GlassContainer(
                      padding: EdgeInsets.all(isSmall ? 24 : 48),
                      width: isSmall ? double.infinity : 480,
                      borderRadius: 32,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'logo',
                              child: Image.asset('assets/images/moonsun_logo.png', width: isSmall ? 80 : 100, height: isSmall ? 80 : 100),
                            ),
                            SizedBox(height: isSmall ? 24 : 32),
                            Text(
                              "STATION PORTAL",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white24 : Colors.black26,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sign In to Station",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: isSmall ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : StyleConstants.lightText,
                              ),
                            ),
                            SizedBox(height: isSmall ? 32 : 48),

                            _buildTextField(
                              controller: _usernameController,
                              label: "Username",
                              icon: Icons.person_outline_rounded,
                              isDark: isDark,
                              validator: (v) => v!.isEmpty ? "Enter username" : null,
                            ),
                            const SizedBox(height: 24),

                            _buildTextField(
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              isDark: isDark,
                              onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              validator: (v) => v!.isEmpty ? "Enter password" : null,
                              onFieldSubmitted: (v) => _handleLogin(),
                            ),
                            SizedBox(height: isSmall ? 32 : 48),

                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(
                                        "AUTHORIZE & SIGN IN",
                                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    required bool isDark,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
      validator: validator,
    );
  }
}

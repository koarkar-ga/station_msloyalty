import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/ThemeProvider.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class MsAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;

  const MsAppBar({
    super.key,
    this.title = 'Dashboard',
    this.actions,
    this.bottom,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  State<MsAppBar> createState() => _MsAppBarState();
}

class _MsAppBarState extends State<MsAppBar> {
  final String apiHealthUrl = "${AppConfig.apiUrl}/api/health";
  final String apiUrl = "${AppConfig.apiUrl}/api/sales/recent";
  final String apiEhoSendCount = "${AppConfig.apiUrl}/api/eho/send-count";

  bool _isApiOnline = false;
  bool _isEhoUpdate = false;
  String _apiError = "";
  Timer? _timer;
  int _ehoRemainingToSendCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      checkApiConnection();
      _ehoRemainingToSend();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> checkApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.apiHealthUrl))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isApiOnline = true;
            _apiError = "";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isApiOnline = false;
            _apiError = "HTTP ${response.statusCode}: ${response.reasonPhrase}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApiOnline = false;
          _apiError = e.toString();
        });
      }
    }
    return _isApiOnline;
  }

  Future<void> _ehoRemainingToSend() async {
    try {
      final response = await http
          .get(Uri.parse(apiEhoSendCount))
          .timeout(const Duration(seconds: 15));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _ehoRemainingToSendCount = data[0]['COUNT'];
          _isEhoUpdate = _ehoRemainingToSendCount < 100;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ehoRemainingToSendCount = 0;
          _isEhoUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final isCompact = screenWidth < 900;
    final isVeryCompact = screenWidth < 650;

    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : StyleConstants.lightText,
              ),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color:
              (isDark
                      ? StyleConstants.darkSurface
                      : StyleConstants.lightSurface)
                  .withOpacity(0.95),
          border: Border(
            bottom: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Image.asset('assets/images/moonsun_logo.png', height: 30),
          if (!isSmall) ...[
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : StyleConstants.lightText,
                fontSize: 18,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.actions != null) ...widget.actions!,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIndicator(isVeryCompact),
            if (!isVeryCompact)
              const VerticalDivider(
                width: 1,
                indent: 15,
                endIndent: 15,
                color: Colors.white24,
              ),

            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.amber : StyleConstants.lightAccent,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),

            if (!isCompact) ...[
              const SizedBox(width: 10),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.more_time),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              const SizedBox(width: 16),
              _buildDateTime(),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ],
      bottom: widget.bottom,
    );
  }

  Widget _buildDateTime() {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('dd-MM-yyyy').format(now),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              DateFormat('hh:mm aa').format(now),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool compact) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent,
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          Text(
            _isEhoUpdate
                ? "EHO ONLINE : $_ehoRemainingToSendCount"
                : "EHO OFFLINE : $_ehoRemainingToSendCount",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isEhoUpdate ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
        const SizedBox(width: 15),
        Icon(
          Icons.circle,
          size: 10,
          color: _isApiOnline ? Colors.greenAccent : Colors.redAccent,
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isApiOnline
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 10),
                            Text("API Connection Error"),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("The app cannot connect to the POS API server.", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("URL: ${AppConfig.apiHealthUrl}"),
                            const SizedBox(height: 10),
                            const Text("Error Details:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(_apiError, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              checkApiConnection();
                            },
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  },
            child: Text(
              _isApiOnline ? "API ONLINE" : "API OFFLINE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isApiOnline ? Colors.greenAccent : Colors.redAccent,
                decoration: _isApiOnline ? null : TextDecoration.underline,
              ),
            ),
          ),
        ],
        if (!compact) const SizedBox(width: 10),
      ],
    );
  }
}

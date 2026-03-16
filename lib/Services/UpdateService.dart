import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UpdateService {
  final supabase = Supabase.instance.client;

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await supabase
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final String latestVersion = response['version_code'];
      final int latestBuildNumber = response['build_number'];
      final bool isMandatory = response['is_mandatory'] ?? false;
      final String? windowsUrl = response['windows_url'];
      final String releaseNotes = response['release_notes'] ?? '';

      debugPrint('Current Version: $currentVersion ($currentBuildNumber)');
      debugPrint('Latest Version: $latestVersion ($latestBuildNumber)');

      if (latestBuildNumber > currentBuildNumber) {
        debugPrint('Update found! Version: $latestVersion, Build: $latestBuildNumber, URL: $windowsUrl');
        if (context.mounted) {
          await _showUpdateDialog(context, latestVersion, releaseNotes, windowsUrl, isMandatory);
        }
      } else {
        debugPrint('No updates available. Current build: $currentBuildNumber, Latest build: $latestBuildNumber');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  Future<void> _showUpdateDialog(BuildContext context, String version, String notes, String? url, bool isMandatory) async {
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isMandatory,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Text('Update Available (v$version)', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A new version of the app is available. Please update to enjoy the latest features and fixes.',
                style: TextStyle(color: Colors.white70),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Release Notes:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(color: Colors.white60)),
              ],
              if (url == null || url.isEmpty) ...[
                const SizedBox(height: 16),
                const Text('Warning: Download link is not available.', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later', style: TextStyle(color: Colors.white54)),
              ),
            ElevatedButton(
              onPressed: (url == null || url.isEmpty) ? null : () async {
                try {
                  final uri = Uri.parse(url);
                  debugPrint('Launching URL: $url');
                  bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!launched) {
                    debugPrint('Could not launch using externalApplication mode, trying platformDefault');
                    launched = await launchUrl(uri);
                  }
                  if (!launched) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open the download link. Please contact support.')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error launching URL: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening link: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}

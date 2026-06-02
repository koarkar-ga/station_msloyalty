import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  final supabase = Supabase.instance.client;

  bool _isDirectLink(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    
    // Direct link to files
    if (path.endsWith('.apk') || path.endsWith('.zip') || path.endsWith('.exe')) {
      return true;
    }
    
    // Direct link to Supabase Storage objects
    if (uri.host.contains('supabase.co') && uri.path.contains('/storage/v1/object/public/')) {
      return true;
    }
    
    return false;
  }

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await supabase
          .from('app_versions')
          .select()
          .eq('app_type', 'station_app')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final String latestVersion = response['version_code'];
      final int latestBuildNumber = response['build_number'];
      final bool isMandatory = response['is_mandatory'] ?? false;
      final String releaseNotes = response['release_notes'] ?? '';

      String? downloadUrl;
      if (Platform.isAndroid) {
        downloadUrl = response['android_url'];
      } else if (Platform.isWindows) {
        downloadUrl = response['windows_url'];
      } else if (Platform.isIOS) {
        downloadUrl = response['ios_url'];
      }

      debugPrint('Current Version: $currentVersion ($currentBuildNumber)');
      debugPrint('Latest Version: $latestVersion ($latestBuildNumber)');

      if (latestBuildNumber > currentBuildNumber) {
        final bool isDirect = _isDirectLink(downloadUrl);
        debugPrint('Update found! Version: $latestVersion, Build: $latestBuildNumber, Direct: $isDirect, URL: $downloadUrl');
        if (context.mounted) {
          await _showUpdateDialog(context, latestVersion, releaseNotes, downloadUrl, isMandatory, isDirect);
        }
      } else {
        debugPrint('No updates available. Current build: $currentBuildNumber, Latest build: $latestBuildNumber');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    String version,
    String notes,
    String? url,
    bool isMandatory,
    bool isDirect,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => _UpdateDialog(
        version: version,
        notes: notes,
        url: url,
        isMandatory: isMandatory,
        isDirect: isDirect,
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String notes;
  final String? url;
  final bool isMandatory;
  final bool isDirect;

  const _UpdateDialog({
    required this.version,
    required this.notes,
    required this.url,
    required this.isMandatory,
    required this.isDirect,
  });

  @override
  _UpdateDialogState createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Preparing download...';
  String _errorText = '';
  final CancelToken _cancelToken = CancelToken();

  @override
  void dispose() {
    if (_isDownloading) {
      _cancelToken.cancel();
    }
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (widget.url == null || widget.url!.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Downloading update (0%)...';
      _errorText = '';
    });

    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      
      String extension = '.zip';
      if (widget.url!.toLowerCase().contains('.apk')) {
        extension = '.apk';
      } else if (widget.url!.toLowerCase().contains('.exe')) {
        extension = '.exe';
      } else if (Platform.isAndroid) {
        extension = '.apk';
      }

      final String localFileName = 'update_v${widget.version}$extension';
      final String savePath = '${tempDir.path}/$localFileName';

      debugPrint('Downloading update from ${widget.url} to $savePath');

      await dio.download(
        widget.url!,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final double progressValue = received / total;
            final int percentage = (progressValue * 100).toInt();
            setState(() {
              _progress = progressValue;
              _statusText = 'Downloading update ($percentage%)...';
            });
          }
        },
      );

      setState(() {
        _statusText = 'Applying update, please wait...';
      });

      if (Platform.isAndroid) {
        final openResult = await OpenFile.open(savePath);
        debugPrint('OpenFile result on Android: ${openResult.message}');
        exit(0);
      } else if (Platform.isWindows) {
        if (extension == '.exe') {
          final openResult = await OpenFile.open(savePath);
          debugPrint('OpenFile result on Windows (EXE): ${openResult.message}');
          exit(0);
        } else {
          await _runWindowsUpdater(savePath);
        }
      } else {
        final openResult = await OpenFile.open(savePath);
        debugPrint('OpenFile result on other platform: ${openResult.message}');
        exit(0);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorText = 'Download failed: $e';
        });
      }
    }
  }

  Future<void> _runWindowsUpdater(String zipPath) async {
    try {
      final String appExe = Platform.resolvedExecutable;
      final String appDir = File(appExe).parent.path;
      final String tempDir = Directory.systemTemp.path;
      final String batPath = '$tempDir\\apply_update.bat';

      final String batContent = '''
@echo off
title Updating POS Loyalty System...
echo Waiting for application to exit...
timeout /t 2 /nobreak > nul

echo Extracting update files...
powershell -Command "Expand-Archive -Path '$zipPath' -DestinationPath '$appDir' -Force"

if %ERRORLEVEL% NEQ 0 (
  echo --------------------------------------------------
  echo Update Failed!
  echo Could not replace application files.
  echo Please make sure the application is closed.
  echo --------------------------------------------------
  pause
  exit
)

echo Starting application...
start "" "$appExe"
exit
''';

      await File(batPath).writeAsString(batContent);
      debugPrint('Writing updater batch file to $batPath');

      await Process.start('cmd.exe', ['/c', batPath], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      debugPrint('Failed to run Windows updater script: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorText = 'Failed to apply update: $e';
        });
      }
    }
  }

  Future<void> _launchBrowser() async {
    if (widget.url == null || widget.url!.isEmpty) return;
    try {
      final uri = Uri.parse(widget.url!);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri);
      }
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the download link.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isMandatory && !_isDownloading,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF38BDF8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Available (v${widget.version})',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading) ...[
              const Text(
                'A new version of the app is available. Please update to enjoy the latest features and fixes.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (widget.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Release Notes:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.maxFinite,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.notes,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ),
              ],
              if (widget.url == null || widget.url!.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Warning: Download link is not available.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ],
              if (_errorText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ] else ...[
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: const Color(0xFF38BDF8),
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              const Text(
                'Do not close the application while the update is being downloaded.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ],
        ),
        actions: _isDownloading
            ? (widget.isMandatory
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        _cancelToken.cancel();
                        setState(() {
                          _isDownloading = false;
                        });
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ])
            : [
                if (!widget.isMandatory)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later', style: TextStyle(color: Colors.white54)),
                  ),
                ElevatedButton(
                  onPressed: (widget.url == null || widget.url!.isEmpty)
                      ? null
                      : () {
                          if (widget.isDirect) {
                            _startDownload();
                          } else {
                            _launchBrowser();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(widget.isDirect ? 'Update Now' : 'Download in Browser'),
                ),
              ],
      ),
    );
  }
}

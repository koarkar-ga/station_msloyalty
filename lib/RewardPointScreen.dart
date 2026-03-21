import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Helper/BuildRedemptionHistory.dart';
import 'package:station_msloyalty/Helper/BuildRewardGridViewer.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:station_msloyalty/Services/ActivityService.dart';
import 'package:station_msloyalty/Helper/RewardQrScannerDialog.dart';
import 'package:station_msloyalty/Model/OfflineTransaction.dart';
import 'package:isar/isar.dart';

class RewardPointScreen extends StatefulWidget {
  const RewardPointScreen({super.key});

  @override
  _RewardPointScreenState createState() => _RewardPointScreenState();
}

class _RewardPointScreenState extends State<RewardPointScreen> {
  bool _useCameraScanner = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useCameraScanner = prefs.getBool('use_camera_scanner') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MsAppBar(title: "Reward Points Management", showBackButton: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [StyleConstants.darkBg, const Color(0xFF1E293B)]
                : [StyleConstants.lightBg, const Color(0xFFE2E8F0)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 1000;

            if (isMobile) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // --- Top Section: Reward Catalog ---
                        _buildGlassHeader(
                          "Reward Catalog",
                          Icons.grid_view_rounded,
                          context,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height:
                              500, // Fixed height for grid on scrollable mobile view
                          child: GlassContainer(child: buildRewardGridView()),
                        ),
                        const SizedBox(height: 24),
                        // --- Bottom Section: Recent Redemptions ---
                        _buildGlassHeader(
                          "Recent Activity",
                          Icons.history_rounded,
                          context,
                        ),
                        const SizedBox(height: 16),
                        // We use a fixed height or Wrap to avoid overflow in SingleChildScrollView
                        SizedBox(
                          height: 400,
                          child: GlassContainer(
                            child: const RedemptionHistoryList(),
                          ),
                        ),
                        const SizedBox(height: 80), // Space for FAB
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildQRScanAction(context),
                  ),
                ],
              );
            }

            return Row(
              children: [
                // --- Left Panel: Reward Catalog ---
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildGlassHeader(
                          "Reward Catalog",
                          Icons.grid_view_rounded,
                          context,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GlassContainer(child: buildRewardGridView()),
                        ),
                        const SizedBox(height: 16),
                        _buildQRScanAction(context),
                      ],
                    ),
                  ),
                ),

                // --- Right Panel: Recent Redemptions ---
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                    child: Column(
                      children: [
                        _buildGlassHeader(
                          "Recent Activity",
                          Icons.history_rounded,
                          context,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GlassContainer(
                            child: const RedemptionHistoryList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassHeader(String title, IconData icon, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark
                ? StyleConstants.darkAccent
                : StyleConstants.lightAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : StyleConstants.lightText,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanAction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.bottomRight,
      child: FloatingActionButton.extended(
        onPressed: _showQRScannerDialog,
        backgroundColor: isDark
            ? StyleConstants.darkAccent
            : StyleConstants.lightAccent,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          "SCAN REWARD QR",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
    );
  }

  void _showQRScannerDialog() {
    final bool isMobile = MediaQuery.of(context).size.width < 750;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return RewardQrScannerDialog(
          useCameraScanner: _useCameraScanner || isMobile,
          onScan: (qrData) {
            Navigator.pop(context);
            _processRedemption(qrData);
          },
        );
      },
    );
  }

  Future<void> redeemReward(
    String userId,
    int rewardId,
    int requiredPoints, {
    String? tokenId,
  }) async {
    try {
      BotToast.showLoading();
      await Supabase.instance.client.rpc(
        'process_reward_redemption',
        params: {
          'target_user_id': userId,
          'target_reward_id': rewardId,
          'required_points': requiredPoints,
          'target_station_id': AppConfig.stationId,
        },
      );
      if (tokenId != null) {
        await Supabase.instance.client
            .from('qr_tokens')
            .update({'is_used': true})
            .eq('id', tokenId);
      }

      // Log Reward Redemption Activity
      await ActivityService.logActivity(
        actionType: 'redeem_reward',
        description:
            'Redeemed Reward (ID: $rewardId) for Points: $requiredPoints',
        metadata: {
          'reward_id': rewardId,
          'member_uid': userId,
          'points_spent': requiredPoints,
          'token_id': tokenId,
        },
      );

      _showSuccess("Redemption Successful!");
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("Points မလုံလောက်ပါ")) {
        _showError("ယူဆာတွင် Points မလုံလောက်ပါ။ (Insufficient Points)");
      } else {
        _showError("Failed to redeem: $e");
      }
    } finally {
      BotToast.closeAllLoading();
      setState(() {});
    }
  }

  Future<void> _handleOfflineRedeem(String userId, int rewardId, int requiredPoints, {String? tokenId}) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Connection Offline"),
        content: const Text("စနစ်ကို ချိတ်ဆက်မရပါ။ ဤ Reward ကို အော့ဖ်လိုင်း သိမ်းဆည်းထားလိုပါသလား?\n(အွန်လိုင်းရောက်မှသာ အောင်မြင်ကြောင်း အတည်ပြုနိုင်မည်ဖြစ်ပါသည်။)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save Offline")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final offlineTx = OfflineTransaction()
        ..actionType = OfflineActionType.redeem
        ..targetUid = userId
        ..rewardId = rewardId
        ..requiredPoints = requiredPoints
        ..dynamicTokenId = tokenId
        ..stationId = AppConfig.stationId
        ..createdAt = DateTime.now()
        ..isSynced = false;

      await AppConfig.isar.writeTxn(() async {
        await AppConfig.isar.offlineTransactions.put(offlineTx);
      });

      _showSuccess("Offline သိမ်းဆည်းပြီးပါပြီ။ Sync ပြန်လုပ်ပေးရန် လိုအပ်ပါသည်။");
    } catch (e) {
      _showError("Offline Save Error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 400,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 400,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _processRedemption(String qrData) async {
    String trimmedData = qrData.trim();
    if (trimmedData.isEmpty) return;

    String? targetUserId;
    int? targetRewardId;
    int? pointsToRedeem;
    String? currentTokenId;

    try {
      final String upperData = trimmedData.toUpperCase();
      if (upperData.contains('REDEEM|')) {
        int index = upperData.indexOf('REDEEM|');
        String actualData = trimmedData.substring(index);
        currentTokenId = actualData.split('|')[1].trim();

        BotToast.showLoading();
        final tokenResponse = await Supabase.instance.client
            .from('qr_tokens')
            .select('*, gift_cards(points_required)')
            .eq('id', currentTokenId)
            .maybeSingle();

        BotToast.closeAllLoading();
        if (tokenResponse == null) {
          _showError("Invalid QR Token (မတွေ့ရှိပါ)");
          return;
        }
        if (tokenResponse['is_used'] == true) {
          _showError("ဒီ QR Code ကို အသုံးပြုပြီးသားဖြစ်နေပါသည်");
          return;
        }
        if (tokenResponse['action_type'] != 'redeem') {
          _showError("Wrong QR Type: EARN QR ကို Redeem မှာ သုံးလို့မရပါ။");
          return;
        }
        DateTime expiresAt = DateTime.parse(tokenResponse['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          _showError("QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)");
          return;
        }
        targetUserId = tokenResponse['user_id'];
        targetRewardId = tokenResponse['reward_id'];

        // Safely extract points_required
        var gcData = tokenResponse['gift_cards'];
        if (gcData is Map) {
          pointsToRedeem = gcData['points_required'] ?? 0;
        } else if (gcData is List && gcData.isNotEmpty) {
          pointsToRedeem = gcData[0]['points_required'] ?? 0;
        }
      } else {
        List<String> parts = trimmedData.split('|');
        if (parts.length != 3) {
          _showError("Invalid QR Format (မှားယွင်းနေပါသည်)");
          return;
        }
        targetUserId = parts[0];
        targetRewardId = int.parse(parts[1]);
        int qrTimestamp = int.parse(parts[2]);
        int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if ((currentTimestamp - qrTimestamp) > 300) {
          _showError("QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)");
          return;
        }

        final rewardData = await Supabase.instance.client
            .from('gift_cards')
            .select('points_required')
            .eq('id', targetRewardId!)
            .single();
        pointsToRedeem = rewardData['points_required'] ?? 0;
      }

      if (targetUserId != null && targetRewardId != null && pointsToRedeem != null) {
        await redeemReward(targetUserId, targetRewardId, pointsToRedeem, tokenId: currentTokenId);
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('HttpException') ||
          errorStr.contains('HandshakeException') ||
          errorStr.contains('Network') ||
          errorStr.contains('failed to connect')) {
        
        if (targetUserId != null && targetRewardId != null && pointsToRedeem != null) {
          _handleOfflineRedeem(targetUserId, targetRewardId, pointsToRedeem, tokenId: currentTokenId);
        } else {
           _showError("Network Error: အော့ဖ်လိုင်း သိမ်းဆည်းရန်အတွက် QR အချက်အလက် မပြည့်စုံပါ။");
        }
      } else {
         _showError("စနစ်ချို့ယွင်းချက်: $e");
      }
    } finally {
      BotToast.closeAllLoading();
    }
  }
}

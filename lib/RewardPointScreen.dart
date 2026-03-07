import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/BuildQrView.dart';
import 'package:station_msloyalty/Helper/BuildRedemptionHistory.dart';
import 'package:station_msloyalty/Helper/BuildRewardGridViewer.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardPointScreen extends StatefulWidget {
  @override
  _RewardPointScreenState createState() => _RewardPointScreenState();
}

class _RewardPointScreenState extends State<RewardPointScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _qrController = TextEditingController();
  late AnimationController _animationController;
  final FocusNode _qrFocusNode = FocusNode();
  bool _isLoading = true;

  // ၁။ Variable ကြေညာမယ်
  bool _isManualInputEnabled = false;

  @override
  void initState() {
    super.initState();
    // Screen ပွင့်တာနဲ့ QR ဖတ်ဖို့ အသင့်ဖြစ်အောင် Focus ပေးထားမယ်
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _qrFocusNode.requestFocus();
    });
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _toggleManualInput(_isManualInputEnabled);
    // _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Future<void> _loadSettings() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     // သိမ်းထားတာမရှိရင် Default အနေနဲ့ false (Scanner only) ထားမယ်
  //     _isManualInputEnabled = prefs.getBool('isManualInputEnabled') ?? false;
  //   });
  // }

  // ၃။ သားကြီး ခေါ်ချင်တဲ့ _toggleManualInput Function
  Future<void> _toggleManualInput(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isManualInputEnabled', value);
    setState(() {
      _isManualInputEnabled = value;
    });

    // Feedback ပေးဖို့ (Optional)
    _showSuccess(value ? "Manual Input Enabled" : "Manual Input Disabled");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MsAppBar(title: "Redemptions"),
        actions: [
          ToggleButtons(
            children: <Widget>[Icon(Icons.keyboard), Icon(Icons.qr_code_scanner_outlined)],
            isSelected: [_isManualInputEnabled, !_isManualInputEnabled],
            onPressed: (int index) {
              _toggleManualInput(index == 0);
              print("Manual Input: ${_isManualInputEnabled}");
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // --- Left Panel: Reward Catalog (လဲလှယ်နိုင်သော ပစ္စည်းများ) ---
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildHeader("Reward Catalog"),
                  Expanded(child: buildRewardGridView()), // Reward items list
                  _buildQRScanButton(), // QR Input Section
                ],
              ),
            ),
          ),

          // --- Right Panel: Recent Redemptions (လဲလှယ်ပြီးသား မှတ်တမ်း) ---
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  _buildHeader("Recent Redemptions"),
                  Expanded(child: buildRedemptionHistory()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ၂။ QR Input Area (စာရိုက်လို့မရအောင် readOnly လုပ်ထားမယ်)
  Widget _buildQRScanButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.extended(
          onPressed: _showQRScannerDialog,
          backgroundColor: Colors.teal,
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: const Text("Scan Reward QR", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showQRScannerDialog() {
    _qrController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Focus ကို ပေးထားမြဲဖြစ်ရမယ် (Scanner အတွက်)
        Future.delayed(Duration.zero, () => _qrFocusNode.requestFocus());

        return AlertDialog(
          backgroundColor: Colors.blueGrey[900],
          title: Row(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.blue),
              const SizedBox(width: 10),
              const Text("Scan Reward QR", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 100,
                    child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 52),
                  ),
                  SizedBox(width: 8),
                  Positioned(
                    top: 160,
                    child: Text(
                      "QR Code ကို Scan ဖတ်ပါ",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  buildQRView(_animationController),
                ],
              ),
              // Settings မှာ On ထားရင် TextField ကို ပြမယ်၊ Off ထားရင် ဝှက်ထားမယ်
              _isManualInputEnabled
                  ? TextField(
                      controller: _qrController,
                      focusNode: _qrFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Enter QR Code Manually",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          Navigator.pop(context);
                          _processRedemption(value);
                        }
                      },
                    )
                  : Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 1,
                        width: 1,
                        child: TextField(
                          controller: _qrController,
                          focusNode: _qrFocusNode,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              Navigator.pop(context);
                              _processRedemption(value);
                            }
                          },
                        ),
                      ),
                    ),

              !_isManualInputEnabled
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                          Text("Please use your QR Scanner", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Icon(Icons.keyboard, color: Colors.white),
                          Text("Please use your Keyboard", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
            ),
            // Manual ဖွင့်ထားရင် Submit button လေး ထည့်ပေးမယ်
            if (_isManualInputEnabled)
              ElevatedButton(
                onPressed: () {
                  if (_qrController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _processRedemption(_qrController.text);
                  }
                },
                child: const Text("Submit"),
              ),
          ],
        );
      },
    );
  }

  Future<void> redeemReward(String userId, int rewardId) async {
    try {
      // RPC ကို ခေါ်လိုက်တာနဲ့ Point နှုတ်တာရော History သွင်းတာရော တစ်ခါတည်း ပြီးမယ်
      await Supabase.instance.client.rpc(
        'process_reward_redemption',
        params: {'target_user_id': userId, 'target_reward_id': rewardId},
      );

      _showSuccess("Redemption Successful!");
    } catch (e) {
      _showError("Failed to redeem: $e");
    }
  }

  // Error ပြရန်
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 300,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Success ပြရန်
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        width: 300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ၃။ QR Data ကို ခွဲထုတ်ပြီး တိုက်စစ်မည့် Logic
  void _processRedemption(String qrData) async {
    try {
      // data format: user123|reward1|1708098335
      List<String> parts = qrData.split('|');
      if (parts.length != 3) throw "Invalid QR Format";

      String userId = parts[0];
      int rewardId = int.parse(parts[1]);
      int qrTimestamp = int.parse(parts[2]);

      // ၁။ အချိန်စစ်မယ် (၅ မိနစ်ထက် ကျော်နေရင် Expired)
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((currentTimestamp - qrTimestamp) > 300) {
        _showError("QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)");
        return;
      }

      // ၂။ Database မှာ တိုက်စစ်မယ်
      // Node.js API ဆီ လှမ်းပို့ပြီး point လောက်မလောက်နဲ့ redeem လုပ်မယ့် logic ခေါ်ပါ
      redeemReward(userId, rewardId);
    } catch (e) {
      _showError("စနစ်ချို့ယွင်းချက်: $e");
    } finally {
      _qrController.clear();
      _qrFocusNode.requestFocus();
    }
  }

  // UI Components (Headers)
  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(15),
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // Left Side Reward List Builder
  Widget _buildRewardList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        leading: Icon(Icons.card_giftcard, color: Colors.orange),
        title: Text("Reward Item $index"),
        subtitle: Text("Required: ${500 + (index * 100)} Points"),
        trailing: Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}

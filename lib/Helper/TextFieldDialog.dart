import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/config.dart' as Config;
import 'package:supabase_flutter/supabase_flutter.dart';

class TextFieldDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final String voc_no;
  final String vehical_no;
  final String fuel_type;
  final String amount;
  final String sale_type;

  const TextFieldDialog({
    super.key,
    required this.supabase,
    required this.voc_no,
    required this.vehical_no,
    required this.fuel_type,
    required this.amount,
    required this.sale_type,
  });

  @override
  _TextFieldDialogState createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<TextFieldDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false; // Loading status ကို ထိန်းချုပ်ရန်
  String? _errorMessage; // Error message ကို UI မှာ ပြရန်

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCollect() async {
    final String qrValue = _controller.text.trim();
    if (qrValue.isEmpty) {
      setState(() => _errorMessage = "QR Code ဖတ်ပေးပါဦး");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ၁။ JSON String ကို Parse လုပ်မယ်
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(qrValue);
      } catch (e) {
        throw "QR ပုံစံ မှားယွင်းနေပါသည်";
      }

      final String targetUid = qrData['uid'] ?? '';
      final int qrTimestamp = qrData['t'] ?? 0;
      final String qrHash = qrData['h'] ?? '';

      // ၂။ Timestamp စစ်ဆေးခြင်း (၃၀ စက္ကန့်အတွင်း ဟုတ်မဟုတ်)
      final int currentMs = DateTime.now().millisecondsSinceEpoch;
      // ကွာခြားချက်ကို စက္ကန့်အဖြစ် ပြောင်းမယ် (abs() က အနှုတ်မထွက်အောင်)
      final int diffInSeconds = ((currentMs - qrTimestamp).abs() / 1000).round();

      if (diffInSeconds > 30) {
        setState(() {
          _errorMessage = "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)";
          _isLoading = false;
        });
        return;
      }

      final double amountVal = double.tryParse(widget.amount) ?? 0;

      // ၃။ Point ပေါင်းရန် RPC ခေါ်ခြင်း (UID နဲ့ Hash ကို ပို့မယ်)
      final res = await widget.supabase.rpc(
        'add_fuel_points',
        params: {
          'target_user_id': targetUid, // JSON ထဲက UID ကို သုံးမယ်
          'station_name': Config.config['database'],
          'fuel_type': widget.fuel_type,
          'amount_mmk': amountVal,
          'v_voc_no': "${Config.config['database']}${widget.voc_no}",
          'v_sale_type': widget.sale_type,
          //'qr_hash': qrHash, // Hash ကိုလည်း Server ဘက်မှာ စစ်ဖို့ ပို့ပေးလိုက်မယ်
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        Navigator.of(context).pop();
        _showSuccessFeedback(res['points_added'].toString());
      } else {
        setState(() {
          _errorMessage = res['message']?.toString() ?? 'Something went wrong';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().contains("QR ပုံစံ")
            ? e.toString()
            : "ချိတ်ဆက်မှု လွဲချော်နေပါသည်။ QR မှန်ကန်မှု ရှိ၊ မရှိ စစ်ဆေးပါ။ \n ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.green),
      onPressed: () => _showScanDialog(),
    );
  }

  void _showScanDialog() {
    _controller.clear();
    _errorMessage = null;
    _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !_isLoading, // Loading ဖြစ်နေရင် အပြင်နှိပ်ပြီး ပိတ်လို့မရအောင် တားမယ်
      builder: (context) => StatefulBuilder(
        // Dialog ထဲမှာ setState အလုပ်လုပ်အောင် သုံးရတယ်
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Point ရယူရန် QR Scan ဖတ်ပါ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSaleInfoCard(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Scan QR Code',
                      errorText: _errorMessage, // Error ရှိရင် ဒီမှာ ပေါ်မယ်
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _handleCollectWithState(setDialogState),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleCollectWithState(setDialogState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  fixedSize: const Size(120, 40),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Collect', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog ရဲ့ internal state ကို update လုပ်ဖို့ helper
  Future<void> _handleCollectWithState(StateSetter setDialogState) async {
    setDialogState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _handleCollect();
    if (mounted)
      setDialogState(() {
        _isLoading = false;
      });
  }

  Widget _buildSaleInfoCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200), // Card ပတ်ပတ်လည် ဘောင်လေးခတ်မယ်
      ),
      color: Colors.grey.shade50, // နောက်ခံကို ခဲဖျော့လေးထားမယ်
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sale Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
            ),
            const Divider(height: 20, thickness: 1), // ခေါင်းစဉ်အောက်က မျဉ်းတားလေး

            _infoRow('Voucher No', widget.voc_no),
            const SizedBox(height: 8),

            _infoRow('Vehicle No', widget.vehical_no.isEmpty ? '-' : widget.vehical_no),
            const SizedBox(height: 8),

            _infoRow('Fuel Type', widget.fuel_type),
            const SizedBox(height: 8),

            _infoRow(
              'Sale Type',
              widget.sale_type,
              valueColor: _getSaleTypeColor(widget.sale_type),
            ),
            const SizedBox(height: 8),

            _infoRow(
              'Amount',
              '${NumberFormat('#,###').format(double.tryParse(widget.amount) ?? 0)} MMK',
              valueColor: Colors.green.shade700,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  // သားကြီးအတွက် Row လေးတွေကို စနစ်တကျ စီပေးမယ့် Helper Widget
  Widget _infoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label အပိုင်း (Fixed width ပေးထားလို့ Colon တွေ ညီနေလိမ့်မယ်)
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
        const Text(' :  ', style: TextStyle(color: Colors.grey)),
        // Value အပိုင်း
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Sale Type အလိုက် အရောင်ခွဲပေးမယ့် logic
  Color _getSaleTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Colors.blue.shade700;
      case 'credit':
        return Colors.orange.shade800;
      case 'fleet':
        return Colors.purple.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  void _showSuccessFeedback(String points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Points $points Collect လုပ်ပြီးပါပြီ။"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

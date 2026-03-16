import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/common.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/Helper/BuildQrView.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:station_msloyalty/config.dart' as Config;

class CameraScannerDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final String vocNo;
  final String vehicalNo;
  final String fuelType;
  final String amount;
  final String saleType;
  final double? unitPrice;
  final double? saleLiter;

  const CameraScannerDialog({
    super.key,
    required this.supabase,
    required this.vocNo,
    required this.vehicalNo,
    required this.fuelType,
    required this.amount,
    required this.saleType,
    this.unitPrice,
    this.saleLiter,
  });

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Scan QR Code using PC Camera",
      icon: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.green),
      onPressed: () {
        _showScannerDialog();
      },
    );
  }

  void _showScannerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ScannerDialogContent(
        vocNo: widget.vocNo,
        vehicalNo: widget.vehicalNo,
        fuelType: widget.fuelType,
        amount: widget.amount,
        saleType: widget.saleType,
        unitPrice: widget.unitPrice,
        saleLiter: widget.saleLiter,
        supabase: widget.supabase,
      ),
    );
  }
}

class _ScannerDialogContent extends StatefulWidget {
  final String vocNo;
  final String vehicalNo;
  final String fuelType;
  final String amount;
  final String saleType;
  final double? unitPrice;
  final double? saleLiter;
  final SupabaseClient supabase;

  const _ScannerDialogContent({
    required this.vocNo,
    required this.vehicalNo,
    required this.fuelType,
    required this.amount,
    required this.saleType,
    this.unitPrice,
    this.saleLiter,
    required this.supabase,
  });

  @override
  State<_ScannerDialogContent> createState() => _ScannerDialogContentState();
}

class _ScannerDialogContentState extends State<_ScannerDialogContent>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isScannerActive = true;
  AnimationController? _animationController;
  Timer? _processingTimer;
  final MultiFormatReader _reader = MultiFormatReader();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        BotToast.showText(text: "No camera found", contentColor: Colors.red);
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _startScanTimer();
      }
    } catch (e) {
      if (mounted) {
        BotToast.showText(
          text: "Camera Error: $e",
          contentColor: Colors.orange,
        );
      }
    }
  }

  void _startScanTimer() {
    _processingTimer = Timer.periodic(const Duration(milliseconds: 600), (
      _,
    ) async {
      if (!_isScannerActive ||
          _isProcessing ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      try {
        final file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        if (mounted) {
          _decodeQR(bytes, context);
        }
      } catch (_) {}
    });
  }

  void _decodeQR(Uint8List jpegBytes, BuildContext dialogContext) {
    try {
      final decoded = img.decodeJpg(jpegBytes);
      if (decoded == null) return;

      final pixels = decoded.getBytes(order: img.ChannelOrder.abgr);
      final int32Pixels = List<int>.generate(decoded.width * decoded.height, (
        i,
      ) {
        final offset = i * 4;
        final a = pixels[offset + 3];
        final b = pixels[offset + 2];
        final g = pixels[offset + 1];
        final r = pixels[offset];
        return (a << 24) | (r << 16) | (g << 8) | b;
      });

      final src = RGBLuminanceSource(
        decoded.width,
        decoded.height,
        int32Pixels,
      );
      final bitmap = BinaryBitmap(HybridBinarizer(src));
      final result = _reader.decode(bitmap);

      final text = result.text;
      if (text.isNotEmpty) {
        _processScannedData(text, dialogContext);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _isScannerActive = false;
    _processingTimer?.cancel();
    _animationController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processScannedData(String qrData, BuildContext dialogContext) async {
    if (_isProcessing) return;
    print("DEBUG: Scanned QR Data: '$qrData'");

    setState(() => _isProcessing = true);
    _isScannerActive = false;

    try {
      BotToast.showLoading();

      String targetUid = '';
      String? dynamicTokenId;
      final String trimmedQr = qrData.trim();
      final String upperQr = trimmedQr.toUpperCase();

      if (upperQr.startsWith('EARN|')) {
        dynamicTokenId = trimmedQr.split('|').last.trim();

        final tokenRes = await widget.supabase
            .from('qr_tokens')
            .select('user_id, expires_at, is_used')
            .eq('id', dynamicTokenId)
            .maybeSingle();

        if (tokenRes == null) throw "QR Token မတွေ့ပါ။ (Invalid Token)";
        if (tokenRes['is_used'] == true) {
          throw "ဒီ QR ကို အသုံးပြုပြီးသား ဖြစ်နေပါသည်။";
        }

        final DateTime expiresAt = DateTime.parse(tokenRes['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          throw "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)";
        }

        targetUid = tokenRes['user_id'];
      } else {
        Map<String, dynamic> parsedQr;
        try {
          parsedQr = Map<String, dynamic>.from(
            qrData.contains('{') ? jsonDecode(qrData) : throw 'bad',
          );
        } catch (_) {
          throw "QR ပုံစံ မှားယွင်းနေပါသည်";
        }

        targetUid = parsedQr['uid'] ?? '';
        final int qrTimestamp = parsedQr['t'] ?? 0;

        if (targetUid.isEmpty) throw "Invalid QR Code: uid empty";

        final int diffSec =
            ((DateTime.now().millisecondsSinceEpoch - qrTimestamp).abs() / 1000)
                .round();
        if (diffSec > 300) {
          throw "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)";
        }
      }

      if (targetUid.isEmpty) throw "User ID မတွေ့ပါ။ QR ပြန်စစ်ပေးပါ။";

      // Fetch today's count and pipd for display/enforcement
      final DateTime now = DateTime.now();
      final String todayStr = DateFormat('yyyy-MM-dd').format(now);
      
      final countRes = await widget.supabase
          .from('fuel_transactions')
          .select('id')
          .eq('user_id', targetUid)
          .gte('created_at', todayStr);
      
      final int todayCount = (countRes as List).length;

      final settingsRes = await widget.supabase
          .from('points_settings')
          .select('pipd')
          .limit(1)
          .maybeSingle();
      
      final int pipd = settingsRes?['pipd'] ?? 1;

      if (todayCount >= pipd) {
        throw "ယနေ့အတွက် Point Limit ပြည့်သွားပါပြီ။ ($todayCount/$pipd ကြိမ်)";
      }

      final String stationId = Config.config['database'] as String;
      final String fullVocNo = "$stationId${widget.vocNo}";
      final existingData = await widget.supabase
          .from('fuel_transactions')
          .select('id')
          .eq('voc_no', fullVocNo)
          .maybeSingle();

      if (existingData != null) {
        BotToast.showText(
          text: "Voucher အမှတ် $fullVocNo အတွက် Point ထည့်သွင်းပြီးဖြစ်ပါသည်။",
          contentColor: Colors.orange,
        );
        Navigator.of(dialogContext).pop();
        return;
      }

      final res = await widget.supabase.rpc(
        'add_fuel_points',
        params: {
          'target_user_id': targetUid,
          'station_id': stationId,
          'fuel_type': widget.fuelType,
          'amount_mmk': double.parse(widget.amount),
          'v_voc_no': fullVocNo,
          'v_sale_type': widget.saleType,
          'v_vehicle_no': widget.vehicalNo,
          'v_payment_type': widget.saleType,
          'v_unit_price': widget.unitPrice,
          'v_sale_liter': widget.saleLiter,
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        if (dynamicTokenId != null) {
          await widget.supabase
              .from('qr_tokens')
              .update({'is_used': true})
              .eq('id', dynamicTokenId);
        }

        if (mounted) {
           Navigator.of(dialogContext).pop(); 
           _showSuccessFeedback(res['points_added'].toString());
        }
      } else {
        throw res['message']?.toString() ?? 'Something went wrong';
      }
    } catch (e) {
      BotToast.showText(text: "Error: $e", contentColor: Colors.red);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScannerActive = true;
        });
      }
    } finally {
      BotToast.closeAllLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.blueGrey[900],
      title: const Text(
        'Point ရယူရန် QR Scan ဖတ်ပါ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSaleInfoCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner, color: Colors.grey, size: 52),
                      SizedBox(height: 10),
                      Text(
                        "Loading Camera...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  if (_animationController != null)
                    buildQRView(_animationController!),
                  const Positioned(
                    bottom: 20,
                    child: Text(
                      "QR Code ကို QR Scanner ဖြင့် Scan ဖတ်ပါ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleInfoCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sale Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            _infoRow('Voucher No', widget.vocNo),
            const SizedBox(height: 8),
            _infoRow(
              'Vehicle No',
              widget.vehicalNo.isEmpty ? '-' : widget.vehicalNo,
            ),
            const SizedBox(height: 8),
            _infoRow('Fuel Type', widget.fuelType),
            const SizedBox(height: 8),
            _infoRow(
              'Sale Type',
              widget.saleType,
              valueColor: _getSaleTypeColor(widget.saleType),
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

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        const Text(' :  ', style: TextStyle(color: Colors.grey)),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  "SUCCESS!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Points $points Collect လုပ်ပြီးပါပြီ။",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

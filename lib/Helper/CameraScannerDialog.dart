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

  const CameraScannerDialog({
    super.key,
    required this.supabase,
    required this.vocNo,
    required this.vehicalNo,
    required this.fuelType,
    required this.amount,
    required this.saleType,
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
  final SupabaseClient supabase;

  const _ScannerDialogContent({
    required this.vocNo,
    required this.vehicalNo,
    required this.fuelType,
    required this.amount,
    required this.saleType,
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
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
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
            text: "Camera Error: $e", contentColor: Colors.orange);
      }
    }
  }

  void _startScanTimer() {
    // Poll every 600ms: take a snapshot & attempt QR decode
    _processingTimer =
        Timer.periodic(const Duration(milliseconds: 600), (_) async {
      if (!_isScannerActive ||
          _isProcessing ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) return;

      try {
        final file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        _decodeQR(bytes);
      } catch (_) {}
    });
  }

  void _decodeQR(Uint8List jpegBytes) {
    try {
      // Decode JPEG → Image (from 'package:image/image.dart')
      final decoded = img.decodeJpg(jpegBytes);
      if (decoded == null) return;

      // Convert to ARGB int list that RGBLuminanceSource expects
      final pixels = decoded.getBytes(order: img.ChannelOrder.abgr);
      final int32Pixels = List<int>.generate(
        decoded.width * decoded.height,
        (i) {
          final offset = i * 4;
          final a = pixels[offset + 3];
          final b = pixels[offset + 2];
          final g = pixels[offset + 1];
          final r = pixels[offset];
          return (a << 24) | (r << 16) | (g << 8) | b;
        },
      );

      final src = RGBLuminanceSource(decoded.width, decoded.height, int32Pixels);
      final bitmap = BinaryBitmap(HybridBinarizer(src));
      final result = _reader.decode(bitmap);

      if (result != null) {
        final text = result.text;
        if (text != null && text.isNotEmpty) {
          _processScannedData(text);
        }
      }
    } catch (_) {
      // No QR found in this frame – silently ignore
    }
  }

  @override
  void dispose() {
    _isScannerActive = false;
    _processingTimer?.cancel();
    _animationController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processScannedData(String qrData) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _isScannerActive = false;

    try {
      BotToast.showLoading();

      // ① Parse JSON  (QR = {"uid":"...","t":timestamp,"h":"..."})
      Map<String, dynamic> parsedQr;
      try {
        parsedQr = Map<String, dynamic>.from(
          qrData.contains('{') ? jsonDecode(qrData) : throw 'bad',
        );
      } catch (_) {
        throw "QR ပုံစံ မှားယွင်းနေပါသည်";
      }

      final String targetUid = parsedQr['uid'] ?? '';
      final int qrTimestamp  = parsedQr['t']   ?? 0;
      if (targetUid.isEmpty) throw "Invalid QR Code: uid empty";

      // ② Timestamp check (5 minutes = 300 seconds)
      final int diffSec = ((DateTime.now().millisecondsSinceEpoch - qrTimestamp).abs() / 1000).round();
      if (diffSec > 300) {
        setState(() {
          _isProcessing = false;
          _isScannerActive = true;
        });
        BotToast.showText(
            text: "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)",
            contentColor: Colors.orange);
        return;
      }

      // ③ Duplicate voc check  
      final String stationId = Config.config['database'] as String;
      final String fullVocNo = "$stationId${widget.vocNo}";
      final existingData = await widget.supabase
          .from('fuel_transactions')
          .select('id')
          .eq('voc_no', fullVocNo)
          .maybeSingle();

      if (existingData != null) {
        BotToast.showText(
            text: "This Voucher has already collected points.",
            contentColor: Colors.orange);
        Navigator.pop(context);
        return;
      }

      // ④ Add points
      final res = await widget.supabase.rpc(
        'add_fuel_points',
        params: {
          'target_user_id': targetUid,
          'station_id': stationId,
          'fuel_type': widget.fuelType,
          'amount_mmk': double.parse(widget.amount),
          'v_voc_no': fullVocNo,
          'v_sale_type': widget.saleType,
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        BotToast.showText(
            text: "Points ${res['points_added']} Collect လုပ်ပြီးပါပြီ",
            contentColor: Colors.green);
        Navigator.pop(context);
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
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                  // 1. Underlay – shown while camera loads
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner,
                          color: Colors.grey, size: 52),
                      SizedBox(height: 10),
                      Text("Loading Camera...",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),

                  // 2. Camera preview
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),

                  // 3. SR scanner animation (red laser line)
                  if (_animationController != null)
                    buildQRView(_animationController!),

                  // 4. Instruction text
                  const Positioned(
                    bottom: 20,
                    child: Text(
                      "QR Code ကို QR Scanner ဖြင့် Scan ဖတ်ပါ",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 5. Processing overlay
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
            const Text('Sale Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey)),
            const Divider(height: 20, thickness: 1),
            _infoRow('Voucher No', widget.vocNo),
            const SizedBox(height: 8),
            _infoRow('Vehicle No',
                widget.vehicalNo.isEmpty ? '-' : widget.vehicalNo),
            const SizedBox(height: 8),
            _infoRow('Fuel Type', widget.fuelType),
            const SizedBox(height: 8),
            _infoRow('Sale Type', widget.saleType,
                valueColor: _getSaleTypeColor(widget.saleType)),
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

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
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
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:zxing_lib/zxing.dart';
import 'package:zxing_lib/common.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:station_msloyalty/Helper/BuildQrView.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class RewardQrScannerDialog extends StatefulWidget {
  final Function(String) onScan;
  final bool useCameraScanner;

  const RewardQrScannerDialog({
    super.key,
    required this.onScan,
    this.useCameraScanner = false,
  });

  @override
  State<RewardQrScannerDialog> createState() => _RewardQrScannerDialogState();
}

class _RewardQrScannerDialogState extends State<RewardQrScannerDialog>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isScannerActive = true;
  AnimationController? _animationController;
  Timer? _processingTimer;
  final MultiFormatReader _reader = MultiFormatReader();

  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _keyboardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.useCameraScanner) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat(reverse: true);
      _initializeCamera();
    }

    // Auto-focus for physical scanners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  Future<void> _initializeCamera() async {
    // ... (rest of _initializeCamera unchanged)
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        BotToast.showText(text: "No camera found", contentColor: Colors.red);
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium, // Increased for better accuracy
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
    _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (
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
          _decodeQR(bytes);
        }
      } catch (_) {}
    });
  }

  void _decodeQR(Uint8List jpegBytes) {
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
        _isScannerActive = false;
        widget.onScan(text);
      }
    } catch (_) {
      // Decode failed, likely no QR in frame
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassContainer(
        width: 500,
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Text(
                  "Scan Reward QR",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (widget.useCameraScanner) ...[
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Placeholder/Camera Preview
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.videocam_off_outlined,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                    ),

                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),

                    // Scanning Animation
                    if (_animationController != null)
                      buildQRView(_animationController!),

                    // Corner Brackets
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Icon(
                Icons.qr_code_scanner,
                size: 150,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 2,
              ),
            ],
            const SizedBox(height: 32),
            Text(
              widget.useCameraScanner
                  ? "Place the QR code within the frame"
                  : "Please scan the QR code using your physical scanner",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (widget.useCameraScanner)
              Text(
                _cameraController == null
                    ? "Initializing Camera..."
                    : "Scanner Active",
                style: TextStyle(
                  color: _cameraController == null
                      ? Colors.orangeAccent
                      : Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                "Waiting for scanner input...",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // Hidden TextField for Physical QR Scanners
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: _keyboardController,
                  focusNode: _keyboardFocusNode,
                  autofocus: true,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _isScannerActive = false;
                      widget.onScan(value.trim());
                    }
                  },
                  onChanged: (value) {
                    if (value.contains('\n') || value.contains('\r')) {
                      _isScannerActive = false;
                      widget.onScan(value.trim());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

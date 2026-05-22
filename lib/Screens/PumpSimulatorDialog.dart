import 'dart:async';
import 'package:flutter/material.dart';
import 'package:station_msloyalty/Screens/InvoiceReceiptPrint.dart';

class PumpSimulatorDialog extends StatefulWidget {
  final int nozzleId;
  final String fuelType;
  final double unitPrice;
  final double targetLiters;
  final double targetAmount;
  final Map<String, dynamic>? member;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const PumpSimulatorDialog({
    super.key,
    required this.nozzleId,
    required this.fuelType,
    required this.unitPrice,
    required this.targetLiters,
    required this.targetAmount,
    this.member,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<PumpSimulatorDialog> createState() => _PumpSimulatorDialogState();
}

class _PumpSimulatorDialogState extends State<PumpSimulatorDialog> {
  Timer? _timer;
  double _dispensedLiters = 0.0;
  double _dispensedAmount = 0.0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    const int totalSteps = 50; // 5 seconds (50 * 100ms)
    final double stepLiters = widget.targetLiters / totalSteps;
    final double stepAmount = widget.targetAmount / totalSteps;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        _dispensedLiters += stepLiters;
        _dispensedAmount += stepAmount;
        _progress = _dispensedLiters / widget.targetLiters;

        if (_progress >= 1.0) {
          _progress = 1.0;
          _dispensedLiters = widget.targetLiters;
          _dispensedAmount = widget.targetAmount;
          _timer?.cancel();
          _timer = null;
          
          _finishFueling();
        }
      });
    });
  }

  void _finishFueling() {
    Navigator.pop(context); // Close simulation dialog
    widget.onComplete();

    // Open receipt print view
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoiceReceiptPrint(
        nozzleId: widget.nozzleId,
        fuelType: widget.fuelType,
        unitPrice: widget.unitPrice,
        liters: widget.targetLiters,
        amount: widget.targetAmount,
        member: widget.member,
      ),
    );
  }

  void _cancelFueling() {
    _timer?.cancel();
    Navigator.pop(context);
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(
                      "Fueling Nozzle ${widget.nozzleId} ...",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  "${(_progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              color: Colors.orangeAccent,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("DISPENSED LITERS", style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(
                        _dispensedLiters.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text("L", style: TextStyle(color: Colors.tealAccent[400], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 60, color: Colors.white12),
                  Column(
                    children: [
                      const Text("TOTAL PRICE", style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(
                        _dispensedAmount.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text("MMK", style: TextStyle(color: Colors.amberAccent[400], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Dispensing ${widget.fuelType} @ ${widget.unitPrice} MMK/L",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelFueling,
                  child: const Text("EMERGENCY STOP", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

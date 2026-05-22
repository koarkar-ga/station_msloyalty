import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Model/OfflineTransaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoiceReceiptPrint extends StatefulWidget {
  final int nozzleId;
  final String fuelType;
  final double unitPrice;
  final double liters;
  final double amount;
  final Map<String, dynamic>? member;

  const InvoiceReceiptPrint({
    super.key,
    required this.nozzleId,
    required this.fuelType,
    required this.unitPrice,
    required this.liters,
    required this.amount,
    this.member,
  });

  @override
  State<InvoiceReceiptPrint> createState() => _InvoiceReceiptPrintState();
}

class _InvoiceReceiptPrintState extends State<InvoiceReceiptPrint> {
  final supabase = Supabase.instance.client;
  bool _isSaving = true;
  String _syncStatus = "Processing...";
  String? _errorMsg;
  String _voucherNo = "";
  int _earnedPoints = 0;

  @override
  void initState() {
    super.initState();
    _generateVoucherNo();
    _saveTransaction();
  }

  void _generateVoucherNo() {
    // Generate a random-like voucher number for mock POS receipt
    final now = DateTime.now();
    final randomStr = (now.microsecondsSinceEpoch % 100000).toString().padLeft(
      5,
      '0',
    );
    final dateStr = DateFormat('yyMMddHHmm').format(now);
    _voucherNo = "VOC-$dateStr-$randomStr";
    _earnedPoints = widget.amount ~/ 1000;
  }

  Future<void> _saveTransaction() async {
    if (widget.member == null) {
      // No loyalty member, no point sync required
      setState(() {
        _isSaving = false;
        _syncStatus = "Success (No Member)";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _syncStatus = "Syncing with Cloud Server...";
    });

    final targetUid = widget.member!['id'];
    final stationId = AppConfig.stationId;

    try {
      // 1. Try to sync to cloud Supabase RPC
      final res = await supabase.rpc(
        'add_fuel_points',
        params: {
          'target_user_id': targetUid,
          'station_id': stationId,
          'fuel_type': widget.fuelType,
          'amount_mmk': widget.amount,
          'v_voc_no': _voucherNo,
          'v_sale_type': 'Cash',
          'v_vehicle_no': '-',
          'v_payment_type': 'Cash',
          'v_unit_price': widget.unitPrice,
          'v_sale_liter': widget.liters,
        },
      );

      if (res != null && res['status'] == 'success') {
        setState(() {
          _syncStatus = "Online Synchronized";
          _isSaving = false;
        });
        BotToast.showText(
          text: "Points updated successfully!",
          contentColor: Colors.green,
        );
      } else {
        throw res?['message']?.toString() ?? 'Failed to add points';
      }
    } catch (e) {
      debugPrint("Cloud sync failed: $e, falling back to local Isar DB");
      // 2. Network offline fallback: Save to Isar DB
      try {
        final offlineTx = OfflineTransaction()
          ..actionType = OfflineActionType.earn
          ..targetUid = targetUid
          ..stationId = stationId
          ..fuelType = widget.fuelType
          ..amountMmk = widget.amount
          ..vocNo = _voucherNo
          ..saleType = 'Cash'
          ..vehicleNo = '-'
          ..paymentType = 'Cash'
          ..unitPrice = widget.unitPrice
          ..saleLiter = widget.liters
          ..createdAt = DateTime.now()
          ..isSynced = false;

        await AppConfig.isar.writeTxn(() async {
          await AppConfig.isar.offlineTransactions.put(offlineTx);
        });

        setState(() {
          _syncStatus = "Saved Offline (Pending Sync)";
          _isSaving = false;
        });
        BotToast.showText(
          text: "Offline Saved! Sync later.",
          duration: const Duration(seconds: 3),
          contentColor: Colors.orangeAccent,
        );
      } catch (isarError) {
        setState(() {
          _syncStatus = "Failed to Save";
          _errorMsg = isarError.toString();
          _isSaving = false;
        });
      }
    }
  }

  void _simulatePrint() {
    BotToast.showLoading();
    Future.delayed(const Duration(seconds: 1), () {
      BotToast.closeAllLoading();
      BotToast.showText(
        text: "Receipt printed successfully!",
        contentColor: Colors.green,
      );
    });
  }

  Future<void> _clearPump() async {
    BotToast.showLoading();
    try {
      final response = await http
          .post(
            Uri.parse("${AppConfig.apiUrl}/api/clear-pump"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"hoseId": widget.nozzleId}),
          )
          .timeout(const Duration(seconds: 5));

      BotToast.closeAllLoading();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint("Cleared nozzle ${widget.nozzleId} in DB.");
        }
      }
    } catch (e) {
      BotToast.closeAllLoading();
      debugPrint("Failed to clear nozzle ${widget.nozzleId}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thermal Receipt Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  "VIRTUAL THERMAL RECEIPT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Receipt Content Area
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAF9),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    Center(
                      child: Column(
                        children: [
                          Text(
                            AppConfig.stationName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "MOONSUN FUEL STATION",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Divider line
                    _buildDashedLine(),
                    const SizedBox(height: 12),

                    _buildReceiptRow("VOUCHER NO", _voucherNo),
                    _buildReceiptRow("DATE", nowStr),
                    _buildReceiptRow("NOZZLE ID", "NOZZLE ${widget.nozzleId}"),
                    _buildReceiptRow("PAYMENT", "CASH"),

                    const SizedBox(height: 12),
                    _buildDashedLine(),
                    const SizedBox(height: 12),

                    _buildReceiptRow("PRODUCT", widget.fuelType),
                    _buildReceiptRow(
                      "UNIT PRICE",
                      "${widget.unitPrice.toStringAsFixed(0)} MMK/L",
                    ),
                    _buildReceiptRow(
                      "VOLUME",
                      "${widget.liters.toStringAsFixed(2)} L",
                    ),

                    const SizedBox(height: 12),
                    _buildDashedLine(),
                    const SizedBox(height: 12),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TOTAL AMOUNT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${widget.amount.toStringAsFixed(0)} MMK",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _buildDashedLine(),
                    const SizedBox(height: 12),

                    // Member Information
                    if (widget.member != null) ...[
                      const Text(
                        "LOYALTY SYSTEM",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildReceiptRow("MEMBER NAME", widget.member!['name']),
                      _buildReceiptRow("PHONE NO", widget.member!['phone']),
                      _buildReceiptRow("POINTS EARNED", "+$_earnedPoints PTS"),
                      const SizedBox(height: 12),
                      _buildDashedLine(),
                      const SizedBox(height: 12),
                    ],

                    // Footer text
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "THANK YOU FOR YOUR PATRONAGE!",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.black45,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "POWERED BY MOONSUN LOYALTY",
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sync Status Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _syncStatus.contains("Online")
                      ? Colors.green.shade50
                      : (_syncStatus.contains("Offline")
                            ? Colors.orange.shade50
                            : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _syncStatus.contains("Online")
                        ? Colors.green.shade200
                        : (_syncStatus.contains("Offline")
                              ? Colors.orange.shade200
                              : Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blueGrey,
                        ),
                      )
                    else
                      Icon(
                        _syncStatus.contains("Online")
                            ? Icons.cloud_done
                            : (_syncStatus.contains("Offline")
                                  ? Icons.cloud_off
                                  : Icons.info),
                        size: 18,
                        color: _syncStatus.contains("Online")
                            ? Colors.green.shade700
                            : (_syncStatus.contains("Offline")
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _syncStatus,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _syncStatus.contains("Online")
                              ? Colors.green.shade800
                              : (_syncStatus.contains("Offline")
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons Bar
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _simulatePrint,
                      icon: const Icon(Icons.print),
                      label: const Text("Print"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        side: const BorderSide(color: Colors.blueGrey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _clearPump();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}

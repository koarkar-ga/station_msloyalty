import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/Services/ActivityService.dart';
import 'package:station_msloyalty/config.dart' as Config;
import 'package:supabase_flutter/supabase_flutter.dart';

class TextFieldDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final String voc_no;
  final String vehical_no;
  final String fuel_type;
  final String amount;
  final String sale_type;
  final double? unit_price;
  final double? sale_liter;

  const TextFieldDialog({
    super.key,
    required this.supabase,
    required this.voc_no,
    required this.vehical_no,
    required this.fuel_type,
    required this.amount,
    required this.sale_type,
    this.unit_price,
    this.sale_liter,
  });

  @override
  _TextFieldDialogState createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<TextFieldDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  bool _isLoading = false;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleCollect(
    BuildContext dialogContext,
    StateSetter? setDialogState,
  ) async {
    final String qrValue = _controller.text.trim();
    if (qrValue.isEmpty) {
      if (setDialogState != null) {
        setDialogState(() => _errorMessage = "QR Code ဖတ်ပေးပါဦး");
      } else {
        setState(() => _errorMessage = "QR Code ဖတ်ပေးပါဦး");
      }
      return;
    }

    if (setDialogState != null) {
      setDialogState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      String targetUid = '';
      String? dynamicTokenId;

      final String upperQr = qrValue.toUpperCase();
      if (upperQr.startsWith('EARN|')) {
        dynamicTokenId = qrValue.split('|').last.trim();

        final tokenRes = await widget.supabase
            .from('qr_tokens')
            .select('user_id, expires_at, is_used')
            .eq('id', dynamicTokenId)
            .maybeSingle();

        if (tokenRes == null) {
          throw "QR Token မတွေ့ပါ။ (Invalid Token)";
        }

        if (tokenRes['is_used'] == true) {
          throw "ဒီ QR ကို အသုံးပြုပြီးသား ဖြစ်နေပါသည်။";
        }

        final DateTime expiresAt = DateTime.parse(tokenRes['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          throw "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)";
        }

        targetUid = tokenRes['user_id'];
      } else {
        Map<String, dynamic> qrData;
        try {
          qrData = jsonDecode(qrValue);
        } catch (e) {
          throw "QR ပုံစံ မှားယွင်းနေပါသည်";
        }

        targetUid = qrData['uid'] ?? '';
        final int qrTimestamp = qrData['t'] ?? 0;

        final int currentMs = DateTime.now().millisecondsSinceEpoch;
        final int diffInSeconds = ((currentMs - qrTimestamp).abs() / 1000)
            .round();

        if (diffInSeconds > 300) {
          throw "QR Code သက်တမ်းကုန်ဆုံးသွားပါပြီ (Expired)";
        }
      }

      if (targetUid.isEmpty) {
        throw "User ID မတွေ့ပါ။ QR ပြန်စစ်ပေးပါ။";
      }

      // Fetch today's count and pipd
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

      final double amountVal = double.tryParse(widget.amount) ?? 0;

      final res = await widget.supabase.rpc(
        'add_fuel_points',
        params: {
          'target_user_id': targetUid,
          'station_id': Config.config['database'],
          'fuel_type': widget.fuel_type,
          'amount_mmk': amountVal,
          'v_voc_no': "${Config.config['database']}${widget.voc_no}",
          'v_sale_type': widget.sale_type,
          'v_vehicle_no': widget.vehical_no,
          'v_payment_type': widget.sale_type,
          'v_unit_price': widget.unit_price,
          'v_sale_liter': widget.sale_liter,
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        final pointsAdded = res['points_added']?.toString() ?? '0';

        if (dynamicTokenId != null) {
          await widget.supabase
              .from('qr_tokens')
              .update({
                'is_used': true,
                'metadata': {'points': pointsAdded},
              })
              .eq('id', dynamicTokenId);
        }

        // Log Point Collection Activity
        await ActivityService.logActivity(
          actionType: 'collect_point',
          description:
              'Collected $pointsAdded points for Voucher ${widget.voc_no}',
          metadata: {
            'voc_no': widget.voc_no,
            'amount': widget.amount,
            'fuel_type': widget.fuel_type,
            'points': pointsAdded,
            'member_uid': targetUid,
          },
        );

        Navigator.of(dialogContext).pop();
        _showSuccessFeedback(res['points_added'].toString());
      } else {
        if (setDialogState != null) {
          setDialogState(() {
            _errorMessage =
                res['message']?.toString() ?? 'Something went wrong';
          });
        } else {
          setState(() {
            _errorMessage =
                res['message']?.toString() ?? 'Something went wrong';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg =
          e.toString().contains("QR ပုံစံ") ||
              e.toString().contains("သက်တမ်းကုန်")
          ? e.toString()
          : "Error: ${e.toString()}";

      if (setDialogState != null) {
        setDialogState(() {
          _errorMessage = errorMsg;
        });
      } else {
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        if (setDialogState != null) {
          setDialogState(() => _isLoading = false);
        } else {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleCollectWithState(
    StateSetter setDialogState,
    BuildContext dialogContext,
  ) async {
    await _handleCollect(dialogContext, setDialogState);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 24,
          color: Color(0xFF10B981),
        ),
      ),
      onPressed: () => _showScanDialog(),
    );
  }

  void _showScanDialog() {
    _controller.clear();
    _errorMessage = null;
    _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF0A192F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 24,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0A192F), Color(0xFF1B4F72)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFD700,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                color: Color(0xFFFFD700),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COLLECT POINTS',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'Scan customer QR to issue points',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildSaleInfoCard(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 1,
                              height: 1,
                              child: TextField(
                                focusNode: _focusNode,
                                enabled: true,
                                controller: _controller,
                                autofocus: true,
                                style: const TextStyle(
                                  color: Colors.transparent,
                                  fontSize: 1,
                                ),
                                cursorColor: Colors.transparent,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onChanged: (val) {
                                  if (val.contains('\n') ||
                                      val.contains('\r')) {
                                    _handleCollectWithState(
                                      setDialogState,
                                      context,
                                    );
                                  }
                                },
                                onSubmitted: (_) => _isLoading
                                    ? null
                                    : _handleCollectWithState(
                                        setDialogState,
                                        context,
                                      ),
                                onTapOutside: (event) => !_isLoading
                                    ? _focusNode.requestFocus()
                                    : null,
                              ),
                            ),
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B4F72,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.05,
                                    child: const Icon(
                                      Icons.rocket_launch_rounded,
                                      size: 120,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_isLoading)
                                    const CircularProgressIndicator(
                                      color: Color(0xFFFFD700),
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: Color(0xFFFFD700),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "READY TO SCAN",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Using hardware QR scanner...",
                                          style: TextStyle(
                                            color: Colors.blueGrey[300],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF0A192F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.4),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _handleCollectWithState(
                                        setDialogState,
                                        context,
                                      ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0A192F),
                                        ),
                                      )
                                    : const Text(
                                        "CONFIRM COLLECTION",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _infoRow(
            'Voucher No',
            widget.voc_no,
            valueColor: const Color(0xFFFFD700),
          ),
          const Divider(height: 24, color: Colors.white10),
          _infoRow(
            'Vehicle No',
            widget.vehical_no.isEmpty ? '-' : widget.vehical_no,
          ),
          const SizedBox(height: 12),
          _infoRow('Fuel Type', widget.fuel_type),
          const SizedBox(height: 12),
          _infoRow(
            'Sale Type',
            widget.sale_type,
            valueColor: _getSaleTypeColor(widget.sale_type),
          ),
          const Divider(height: 24, color: Colors.white10),
          _infoRow(
            'Total Amount',
            '${NumberFormat('#,###').format(double.tryParse(widget.amount) ?? 0)} MMK',
            isBold: true,
            fontSize: 16,
            valueColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.white,
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
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 64,
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "OK",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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

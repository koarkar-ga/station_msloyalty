import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/config.dart' as Config;
import 'package:station_msloyalty/main.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.green),
      tooltip: 'Collect Point',
      onPressed: () async {
        _controller.text = '';
        await showDialog(
          context: context,
          builder: (context) {
            DateTime? _lastTapTime;
            String _scannerBuffer = "";
            return AlertDialog(
              title: const Text('Point ရယူရန်အတွက် QR Scan ဖတ်ပါ'),
              content: Container(
                height: 250,
                child: Column(
                  children: [
                    // Sale info card and collect action
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sale Information',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(child: Text('Voucher No'), width: 150),
                                  Text(' : '),
                                  Text('${widget.voc_no}'),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(child: Text('Vehicle No'), width: 150),
                                  Text(' : '),
                                  Text('${widget.vehical_no.isNotEmpty ? widget.vehical_no : '-'}'),
                                ],
                              ),

                              Row(
                                children: [
                                  SizedBox(child: Text('Fuel Type'), width: 150),
                                  Text(' : '),
                                  Text('${widget.fuel_type.isNotEmpty ? widget.fuel_type : '-'}'),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(child: Text('Sale Type'), width: 150),
                                  Text(' : '),
                                  Text('${widget.sale_type.isNotEmpty ? widget.sale_type : '-'}'),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(child: Text('Amount'), width: 150),
                                  Text(' : '),
                                  Text(
                                    '${NumberFormat('#,###').format(double.tryParse(widget.amount) ?? 0)} MMK',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Card(
                      child: Focus(
                        // onKeyEvent: (FocusNode node, KeyEvent event) {
                        //   // Control Key နှိပ်ထားစဉ် C သို့မဟုတ် V နှိပ်ပါက လျစ်လျူရှုရန်
                        //   if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                        //       event.logicalKey == LogicalKeyboardKey.controlRight) {
                        //     return KeyEventResult
                        //         .handled; // Shortcut ကို အလုပ်မလုပ်အောင် တားလိုက်ခြင်း
                        //   }
                        //   if ((HardwareKeyboard.instance.isControlPressed) &&
                        //       (event.logicalKey == LogicalKeyboardKey.keyV ||
                        //           event.logicalKey == LogicalKeyboardKey.keyC)) {
                        //     return KeyEventResult.handled;
                        //   }
                        //   return KeyEventResult.ignored;
                        // },
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          // --- Copy/Paste/Select လုပ်ခြင်းကို ပိတ်ရန် ---
                          //enableInteractiveSelection: false,

                          // Mouse Cursor ကိုလည်း ပုံမှန်အတိုင်းပဲ ထားရန်
                          mouseCursor: SystemMouseCursors.text,

                          decoration: InputDecoration(
                            labelText: 'Scan QR Only',
                            hintText: 'Keyboard typing is disabled',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.redAccent),
                          ),

                          // Enter နှိပ်လိုက်လျှင်သော်လည်းကောင်း၊ Scanner မှ Enter ပို့လျှင်သော်လည်းကောင်း အလုပ်လုပ်မည့်နေရာ
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _handleSearch(value); // သင်၏ ရှာဖွေမှု Logic ကို ဤနေရာတွင် ခေါ်ပါ
                              _controller
                                  .clear(); // နောက်တစ်ကြိမ် Scan ဖတ်ရန် အလွယ်တကူ ရှင်းထုတ်ခြင်း
                            }
                          },

                          // စာရိုက်တာကို တားဆီးဖို့ onChanged ထဲမှာ စစ်ဆေးမယ်
                          // onChanged: (value) {
                          //   final now = DateTime.now();

                          //   // စာလုံးတစ်လုံးနဲ့ တစ်လုံးကြား ရိုက်တဲ့ကြာချိန်ကို စစ်ဆေးခြင်း
                          //   if (_lastTapTime != null) {
                          //     final difference = now.difference(_lastTapTime!).inMilliseconds;

                          //     // အကယ်၍ စာရိုက်တာ အရမ်းနှေးရင် (လူရိုက်တာဆိုရင်) စာသားကို ဖျက်ပစ်မယ်
                          //     // Scanner က ပုံမှန်အားဖြင့် 1ms ကနေ 10ms အတွင်းပဲ ကြာပါတယ်
                          //     if (difference > 50) {
                          //       _controller.clear();
                          //       return;
                          //     }
                          //   }
                          //   _lastTapTime = now;
                          // },

                          // (Optional) အကယ်၍ စာသားအရေအတွက် တူတာနဲ့ Enter မလိုဘဲ အလုပ်လုပ်စေချင်လျှင်
                          // onChanged: (value) {
                          //   // ဥပမာ - QR Code က အမြဲတမ်း ၁၂ လုံး ဖြစ်နေလျှင်
                          //   if (value.length == 12) {
                          //     _handleSearch(value);
                          //     _controller.clear();
                          //   }
                          // },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: handle the entered value if needed
                    collectPoints(
                      widget.supabase,
                      _controller.text,
                      widget.vehical_no,
                      widget.voc_no,
                      widget.fuel_type,
                      widget.amount.isNotEmpty ? double.tryParse(widget.amount) ?? 0 : 0,
                      widget.sale_type,
                    );
                  },
                  child: const Text('Collect'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //Porint Collection Void
  Future<void> collectPoints(
    SupabaseClient supabase,
    String qrValue,
    String vehicalNo,
    String vocNo,
    String fuelType,
    double amount,
    String saleType,
  ) async {
    try {
      if (amount > 0) {
        try {
          final res = await supabase.rpc(
            'add_fuel_points',
            params: {
              'target_user_id': qrValue, // Customer UUID
              'station_name': Config.config['database'],
              'fuel_type': fuelType,
              'amount_mmk': amount,
              'v_voc_no': "${Config.config['database']}$vocNo",
              'v_sale_type': saleType,
            },
          );

          print('response : ${res.toString()}');
          if (res['status'] == 'success') {
            print("Points added: ${res['points_added']}");
            await supabase.from('notifications').insert({
              'user_id': qrValue,
              'title': 'Points Collected',
              'message':
                  'You have received ${res['points_added']} points for your recent purchase.',
              'type': 'earn point',
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
            Navigator.of(context).pop(); // Dialog ပိတ်ရန်
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
                        );
                      },
                      child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    ),
                    SizedBox(width: 8),
                    Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Text(
                  'Points ${res['points_added']} လက်ခံရရှိပါသည်။',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                ],
              ),
            );
          } else {
            print("Error: ${res['message']}");
            Navigator.of(context).pop(); // Dialog ပိတ်ရန်
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Warning', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Text(res['message']?.toString() ?? 'Unknown error'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                ],
              ),
            );
          }

          if (res.status == 200) {
            final data = res.data;
            print("Points Collected Successfully: ${data['points']}");
            // UI မှာ Success Message ပြရန်
          } else {
            print("Error: ${res.status} - ${res.data}");
            Navigator.of(context).pop(); // Dialog ပိတ်ရန်
          }
        } on Exception catch (e) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text('${e.toString()} \n Invalide QR Data \nError Code : 22P02'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } on FunctionException catch (e) {
      print("Function Error: ${e.reasonPhrase} - ${e.details}");
    } catch (e) {
      print("Unexpected Error: $e");
    }
  }

  void _handleSearch(String qrValue) {
    print("Scanning Success: $qrValue");

    // ဒီနေရာမှာ သင့်ရဲ့ _fetchSalesByQR(qrValue) စတဲ့ function တွေကို ခေါ်သုံးနိုင်ပါတယ်။
  }
}

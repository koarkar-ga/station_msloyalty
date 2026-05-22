import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:station_msloyalty/Screens/PumpSimulatorDialog.dart';
import 'package:station_msloyalty/Screens/InvoiceReceiptPrint.dart';
import 'package:bot_toast/bot_toast.dart';

class FuelPosScreen extends StatefulWidget {
  const FuelPosScreen({super.key});

  @override
  State<FuelPosScreen> createState() => _FuelPosScreenState();
}

class _FuelPosScreenState extends State<FuelPosScreen> {
  final supabase = Supabase.instance.client;

  // Selected state
  int? _selectedNozzle;
  Map<String, dynamic>? _selectedFuelType;
  String _presetType = 'amount'; // 'amount' or 'liter'
  final _presetController = TextEditingController(text: "20000");

  // Member Search
  final _phoneController = TextEditingController();
  bool _isSearchingMember = false;
  Map<String, dynamic>? _selectedMember;

  // Pump Setup & Fuel Types state
  List<Map<String, dynamic>> _hoses = [];
  List<Map<String, dynamic>> _fuelTypes = [];
  bool _isLoadingPumpSetup = false;
  Timer? _statusTimer;
  String _hosesTable = '';

  // Local active status of nozzles
  final Map<int, String> _nozzleStates = {
    1: 'Idle',
    2: 'Idle',
    3: 'Idle',
    4: 'Idle',
    5: 'Idle',
    6: 'Idle',
    7: 'Idle',
    8: 'Idle',
  };

  @override
  void initState() {
    super.initState();
    _fetchPumpSetup();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _presetController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _fetchPumpStatuses();
      }
    });
  }

  Future<void> _fetchPumpStatuses() async {
    try {
      final response = await http
          .get(Uri.parse("${AppConfig.apiUrl}/api/pump-status"))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            data.forEach((key, value) {
              final id = int.tryParse(key);
              if (id != null) {
                _nozzleStates[id] = value.toString();
              }
            });
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch pump statuses: $e");
    }
  }

  Future<void> _fetchPumpSetup() async {
    setState(() => _isLoadingPumpSetup = true);
    try {
      final response = await http
          .get(Uri.parse("${AppConfig.apiUrl}/api/pump-setup"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map &&
            data.containsKey('hoses') &&
            data.containsKey('grades')) {
          setState(() {
            _hosesTable = data['hosesTable']?.toString() ?? '';
            _hoses = List<Map<String, dynamic>>.from(data['hoses']);
            _fuelTypes = List<Map<String, dynamic>>.from(
              data['grades'].map((item) {
                return {
                  'id': item['fuelTypeCode']?.toString() ?? '',
                  'name': item['fuelTypeName']?.toString() ?? 'Octane',
                  'price':
                      double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                };
              }),
            );

            // Reinitialize nozzle states for the fetched hoses
            _nozzleStates.clear();
            for (var hose in _hoses) {
              final hoseId =
                  int.tryParse(hose['hoseId']?.toString() ?? '') ?? 1;
              _nozzleStates[hoseId] = 'Idle';
            }
          });
          if (_fuelTypes.isNotEmpty) {
            _selectedFuelType = _fuelTypes.first;
          }
          return;
        }
      }
      throw "Invalid response format";
    } catch (e) {
      debugPrint("POS API pump-setup fetch failed: $e, using fallbacks");
      // Fallback fuel types & hoses
      setState(() {
        _fuelTypes = [
          {'id': '92', 'name': 'Octane 92', 'price': 2350.0},
          {'id': '95', 'name': 'Octane 95', 'price': 2480.0},
          {'id': 'diesel', 'name': 'Diesel', 'price': 2220.0},
          {'id': 'pdiesel', 'name': 'Premium Diesel', 'price': 2300.0},
        ];
        _selectedFuelType = _fuelTypes.first;

        _hoses = [
          {'hoseId': 1, 'pumpNo': 1, 'nozzleNo': 1, 'fuelTypeCode': '92'},
          {'hoseId': 2, 'pumpNo': 1, 'nozzleNo': 2, 'fuelTypeCode': '95'},
          {'hoseId': 3, 'pumpNo': 1, 'nozzleNo': 3, 'fuelTypeCode': 'diesel'},
          {'hoseId': 4, 'pumpNo': 1, 'nozzleNo': 4, 'fuelTypeCode': 'pdiesel'},
          {'hoseId': 5, 'pumpNo': 2, 'nozzleNo': 1, 'fuelTypeCode': '92'},
          {'hoseId': 6, 'pumpNo': 2, 'nozzleNo': 2, 'fuelTypeCode': '95'},
          {'hoseId': 7, 'pumpNo': 2, 'nozzleNo': 3, 'fuelTypeCode': 'diesel'},
          {'hoseId': 8, 'pumpNo': 2, 'nozzleNo': 4, 'fuelTypeCode': 'pdiesel'},
        ];

        _nozzleStates.clear();
        for (var hose in _hoses) {
          final nozzleId = int.tryParse(hose['hoseId']?.toString() ?? '') ?? 1;
          _nozzleStates[nozzleId] = 'Idle';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingPumpSetup = false);
    }
  }

  Future<void> _searchMember() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSearchingMember = true;
      _selectedMember = null;
    });

    try {
      // Lookup profile in cloud DB using supabase
      final profile = await supabase
          .from('profiles')
          .select('id, fullname, phone, points')
          .eq('phone', phone)
          .maybeSingle();

      if (profile != null) {
        setState(() {
          _selectedMember = {
            'id': profile['id'],
            'name': profile['fullname'] ?? 'Unknown Member',
            'phone': profile['phone'] ?? phone,
            'points': profile['points'] ?? 0,
          };
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Member not found in Cloud database."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Search failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingMember = false);
    }
  }

  Future<void> _startFueling() async {
    if (_selectedNozzle == null) {
      _showWarningDialog("Please select a Nozzle first.");
      return;
    }
    if (_selectedFuelType == null) {
      _showWarningDialog("Please select a Fuel Type.");
      return;
    }

    final presetValStr = _presetController.text.trim();
    if (presetValStr.isEmpty ||
        double.tryParse(presetValStr) == null ||
        double.parse(presetValStr) <= 0) {
      _showWarningDialog("Please enter a valid Preset amount or liters.");
      return;
    }

    final double presetValue = double.parse(presetValStr);
    double targetLiters = 0;
    double targetAmount = 0;
    final double price = _selectedFuelType!['price'];

    if (_presetType == 'amount') {
      targetAmount = presetValue;
      targetLiters = targetAmount / price;
    } else {
      targetLiters = presetValue;
      targetAmount = targetLiters * price;
    }

    BotToast.showLoading();
    bool apiSuccess = false;
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.apiUrl}/api/authorize-pump"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "hoseId": _selectedNozzle,
          "presetType": _presetType,
          "presetValue": presetValue,
        }),
      ).timeout(const Duration(seconds: 5));

      BotToast.closeAllLoading();

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == true) {
          apiSuccess = true;
          if (_hosesTable == 'Hoses') {
            BotToast.showText(
              text: "Dispenser Authorized! Please lift nozzle to fuel.",
              contentColor: Colors.green,
              duration: const Duration(seconds: 4),
            );
            setState(() {
              _selectedNozzle = null;
            });
            return;
          }
        }
      }
    } catch (e) {
      BotToast.closeAllLoading();
      debugPrint("API authorization failed: $e. Proceeding locally.");
    }

    if (!apiSuccess && _hosesTable == 'Hoses') {
      _showWarningDialog("Failed to authorize the pump dispenser on the server.");
      return;
    }

    // Set nozzle status to Fueling
    setState(() {
      _nozzleStates[_selectedNozzle!] = 'Fueling';
    });

    // Show Pump Simulator Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PumpSimulatorDialog(
        nozzleId: _selectedNozzle!,
        fuelType: _selectedFuelType!['name'],
        unitPrice: price,
        targetLiters: targetLiters,
        targetAmount: targetAmount,
        member: _selectedMember,
        onComplete: () {
          if (mounted) {
            setState(() {
              _nozzleStates[_selectedNozzle!] = 'Idle';
              _selectedNozzle = null;
              _selectedMember = null;
              _phoneController.clear();
            });
          }
        },
        onCancel: () {
          if (mounted) {
            setState(() {
              _nozzleStates[_selectedNozzle!] = 'Idle';
            });
          }
        },
      ),
    );
  }

  Future<void> _fetchLastSaleAndCheckout(int hoseId) async {
    BotToast.showLoading();
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.apiUrl}/api/sales/lastsale?hoseId=$hoseId&onlyUncleared=true"),
      ).timeout(const Duration(seconds: 5));

      BotToast.closeAllLoading();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map) {
          final double liters = double.tryParse(data['SALELITER']?.toString() ?? '') ?? 0.0;
          final double amount = double.tryParse(data['TotalPrice']?.toString() ?? '') ?? 0.0;
          final double unitPrice = double.tryParse(data['TodayPrice']?.toString() ?? '') ?? 0.0;
          final String fuelType = data['FuelTypeName']?.toString() ?? 'Octane';

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => InvoiceReceiptPrint(
                nozzleId: hoseId,
                fuelType: fuelType,
                unitPrice: unitPrice,
                liters: liters,
                amount: amount,
                member: _selectedMember,
              ),
            ).then((_) {
              setState(() {
                _selectedMember = null;
                _phoneController.clear();
              });
            });
          }
          return;
        }
      }
      _showWarningDialog("No pending/uncleared transaction details found for nozzle $hoseId.");
    } catch (e) {
      BotToast.closeAllLoading();
      _showWarningDialog("Failed to fetch transaction details: $e");
    }
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Validation Warning",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpCard(
    int pumpNo,
    List<Map<String, dynamic>> hoses,
    bool isDark,
  ) {
    // Check nozzle states on this pump
    bool isAnyFueling = false;
    bool isAnyCalling = false;
    for (var hose in hoses) {
      final hoseId = int.tryParse(hose['hoseId']?.toString() ?? '') ?? 0;
      final state = _nozzleStates[hoseId] ?? 'Idle';
      if (state == 'Fueling') {
        isAnyFueling = true;
      } else if (state == 'Calling') {
        isAnyCalling = true;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnyCalling
              ? Colors.redAccent.withValues(alpha: 0.5)
              : (isAnyFueling
                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                  : Colors.white10),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Left: Pump Icon and Number
          SizedBox(
            width: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_gas_station_rounded,
                  size: 22,
                  color: isAnyCalling
                      ? Colors.redAccent
                      : (isAnyFueling ? Colors.orangeAccent : Colors.tealAccent),
                ),
                const SizedBox(height: 2),
                Text(
                  pumpNo.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAnyCalling
                        ? Colors.redAccent
                        : (isAnyFueling ? Colors.orangeAccent : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(color: Colors.white10, width: 12, thickness: 1),
          // Right: Stack of hoses
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: hoses.map((hose) {
                final hoseId =
                    int.tryParse(hose['hoseId']?.toString() ?? '') ?? 0;
                final nozzleNoStr = hose['nozzleNo']?.toString() ?? 'A';
                final fuelTypeCode = hose['fuelTypeCode']?.toString() ?? '';

                final isSelected = _selectedNozzle == hoseId;
                final state = _nozzleStates[hoseId] ?? 'Idle';

                // Find matching fuel type
                final matchingFuel = _fuelTypes.firstWhere(
                  (f) => f['id']?.toString() == fuelTypeCode,
                  orElse: () => <String, dynamic>{'name': 'OCT'},
                );
                final fuelName = matchingFuel['name'] ?? 'OCT';

                Color bgColor = Colors.transparent;
                Color borderColor = Colors.white10;
                Color textColor = Colors.white70;

                if (state == 'Fueling') {
                  bgColor = Colors.orangeAccent.withValues(alpha: 0.15);
                  borderColor = Colors.orangeAccent;
                  textColor = Colors.orangeAccent;
                } else if (state == 'Calling') {
                  bgColor = Colors.redAccent.withValues(alpha: 0.15);
                  borderColor = Colors.redAccent;
                  textColor = Colors.redAccent;
                } else if (state == 'Authorized') {
                  bgColor = Colors.blue.withValues(alpha: 0.15);
                  borderColor = Colors.blue;
                  textColor = Colors.blue;
                } else if (isSelected) {
                  bgColor = Colors.blueAccent.withValues(alpha: 0.2);
                  borderColor = Colors.blueAccent;
                  textColor = Colors.blueAccent;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () {
                      if (state == 'Calling') {
                        _fetchLastSaleAndCheckout(hoseId);
                        return;
                      }
                      if (state == 'Fueling') {
                        _showWarningDialog(
                          "Pump $pumpNo Hose $nozzleNoStr is currently busy fueling.",
                        );
                        return;
                      }
                      setState(() {
                        _selectedNozzle = hoseId;
                        _selectedFuelType = matchingFuel;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "P$pumpNo-$nozzleNoStr-$fuelName",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: Colors.blueAccent,
                            )
                          else if (state == 'Fueling')
                            const Icon(
                              Icons.sync,
                              size: 11,
                              color: Colors.orangeAccent,
                            )
                          else if (state == 'Calling')
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 11,
                              color: Colors.redAccent,
                            )
                          else if (state == 'Authorized')
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 11,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group hoses by pumpNo dynamically
    final Map<int, List<Map<String, dynamic>>> pumpGroups = {};
    for (var hose in _hoses) {
      final pumpNo = int.tryParse(hose['pumpNo']?.toString() ?? '') ?? 1;
      pumpGroups.putIfAbsent(pumpNo, () => []).add(hose);
    }
    final sortedPumps = pumpGroups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Fuel POS Terminal"),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 1,
      ),
      body: Row(
        children: [
          // Left Area: Grid of nozzles & selections
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nozzle Selector",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingPumpSetup)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      ),
                    )
                  else if (_hoses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          "No nozzles configured.",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                      itemCount: sortedPumps.length,
                      itemBuilder: (context, index) {
                        final pumpNo = sortedPumps[index];
                        final pumpHoses = pumpGroups[pumpNo] ?? [];
                        return _buildPumpCard(pumpNo, pumpHoses, isDark);
                      },
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    "Product Selection (Fuel Types)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingPumpSetup)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _fuelTypes.map((fuel) {
                        final isSelected =
                            _selectedFuelType?['id'] == fuel['id'];
                        return InkWell(
                          onTap: () => setState(() => _selectedFuelType = fuel),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal
                                  : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.tealAccent
                                    : Colors.white10,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fuel['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${fuel['price']} MMK",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 32),
                  const Text(
                    "Preset Fuel Configuration",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        fillColor: Colors.blueAccent,
                        selectedColor: Colors.white,
                        color: Colors.white70,
                        isSelected: [
                          _presetType == 'amount',
                          _presetType == 'liter',
                        ],
                        onPressed: (index) {
                          setState(() {
                            _presetType = index == 0 ? 'amount' : 'liter';
                            _presetController.text = _presetType == 'amount'
                                ? '20000'
                                : '10';
                          });
                        },
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text("Amount (MMK)"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text("Volume (Liters)"),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextField(
                          controller: _presetController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: _presetType == 'amount'
                                ? "Enter Amount (MMK)"
                                : "Enter Volume (Liters)",
                            labelStyle: const TextStyle(color: Colors.white38),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              _presetType == 'amount'
                                  ? Icons.monetization_on
                                  : Icons.water_drop,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Vertical divider
          Container(width: 1, color: Colors.white10),

          // Right Area: Member lookup & Checkout summary
          Expanded(
            flex: 2,
            child: Container(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Loyalty Member Lookup",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Enter Mobile Number",
                            hintStyle: TextStyle(color: Colors.white38),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchMember(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSearchingMember ? null : _searchMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: _isSearchingMember
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedMember != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedMember!['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Phone: ${_selectedMember!['phone']}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Current Points: ${_selectedMember!['points']}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text(
                    "Dispense Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    "Selected Nozzle",
                    _selectedNozzle != null
                        ? "Nozzle $_selectedNozzle"
                        : "Not Selected",
                    _selectedNozzle != null ? Colors.white : Colors.white24,
                  ),
                  _buildSummaryRow(
                    "Fuel Type",
                    _selectedFuelType != null
                        ? "${_selectedFuelType!['name']}"
                        : "Not Selected",
                    _selectedFuelType != null ? Colors.white : Colors.white24,
                  ),
                  _buildSummaryRow(
                    "Unit Price",
                    _selectedFuelType != null
                        ? "${_selectedFuelType!['price']} MMK/Liter"
                        : "0 MMK",
                    Colors.white70,
                  ),
                  _buildSummaryRow(
                    "Preset Input",
                    _presetController.text.isNotEmpty
                        ? "${_presetController.text} ${_presetType == 'amount' ? 'MMK' : 'Liters'}"
                        : "-",
                    Colors.white70,
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  _buildSummaryRow(
                    "Loyalty Points To Earn",
                    _presetController.text.isNotEmpty &&
                            _selectedFuelType != null
                        ? "${((_presetType == 'amount' ? double.tryParse(_presetController.text) : double.tryParse(_presetController.text)! * _selectedFuelType!['price']) ?? 0.0) ~/ 1000} Points"
                        : "0 Points",
                    Colors.greenAccent,
                    isBold: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startFueling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Authorize & Start Pump",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

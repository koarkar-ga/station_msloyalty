import 'package:flutter/material.dart';
import 'package:station_msloyalty/Helper/InDevelopmentOverlay.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class SaleEntryScreen extends StatefulWidget {
  const SaleEntryScreen({super.key});

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final TextEditingController _literController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedGrade = '92 Ron';
  double pricePerLiter = 2500.0;

  void _calculateAmount(String value) {
    double liters = double.tryParse(value) ?? 0;
    _amountController.text = (liters * pricePerLiter).toStringAsFixed(0);
  }

  void _calculateLiter(String value) {
    double amount = double.tryParse(value) ?? 0;
    _literController.text = (amount / pricePerLiter).toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const MsAppBar(title: 'Sale Entry', showBackButton: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [StyleConstants.darkBg, const Color(0xFF1E293B)]
                : [StyleConstants.lightBg, const Color(0xFFE2E8F0)],
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // ၁။ ဘယ်ဘက်ခြမ်း - Entry Form
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_document,
                                color: isDark
                                    ? StyleConstants.darkAccent
                                    : StyleConstants.lightAccent,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "SALE RECORD ENTRY",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : StyleConstants.lightText,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.1),
                          ),
                          const SizedBox(height: 24),

                          // Grade ရွေးရန်
                          _buildFieldLabel("Fuel Grade", isDark),
                          DropdownButtonFormField<String>(
                            initialValue: selectedGrade,
                            dropdownColor: isDark
                                ? StyleConstants.darkSurface
                                : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items:
                                ['92 Ron', '95 Ron', 'Premium Diesel', 'Diesel']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => selectedGrade = val),
                          ),

                          const SizedBox(height: 24),

                          // Liter ထည့်ရန်
                          _buildFieldLabel("Liter Amount", isDark),
                          TextField(
                            controller: _literController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.water_drop_outlined),
                              hintText: "0.000",
                              filled: true,
                              fillColor: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _calculateAmount,
                          ),

                          const SizedBox(height: 24),

                          // Amount ထည့်ရန်
                          _buildFieldLabel("Total Amount (MMK)", isDark),
                          TextField(
                            controller: _amountController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.payments_outlined),
                              hintText: "0",
                              filled: true,
                              fillColor: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _calculateLiter,
                          ),

                          const Spacer(),

                          // သိမ်းမည့်ခလုတ်
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? StyleConstants.darkAccent
                                    : StyleConstants.lightAccent,
                                foregroundColor: isDark
                                    ? Colors.black
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined),
                                  SizedBox(width: 12),
                                  Text(
                                    "SAVE SALE RECORD",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
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
                ),

                // ၂။ ညာဘက်ခြမ်း - Recent Sales List
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                          child: Text(
                            "RECENT TRANSACTIONS",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GlassContainer(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: 8,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return GlassContainer(
                                  opacity: 0.05,
                                  borderRadius: 12,
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.local_gas_station,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "92 Ron - 15.500 L",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "May 20, 2024 • 11:20 AM",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.black38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "38,750 MMK",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? StyleConstants.darkAccent
                                              : StyleConstants.lightAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            inDevelopmentOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black45,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

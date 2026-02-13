import 'package:flutter/material.dart';

class SaleEntryScreen extends StatefulWidget {
  const SaleEntryScreen({super.key});

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final TextEditingController _literController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedGrade = '92 Ron';
  double pricePerLiter = 2500.0; // နမူနာ ဈေးနှုန်း

  // Liter ရိုက်ရင် Amount ကို တွက်ပေးတဲ့ Function
  void _calculateAmount(String value) {
    double liters = double.tryParse(value) ?? 0;
    _amountController.text = (liters * pricePerLiter).toStringAsFixed(0);
  }

  // Amount ရိုက်ရင် Liter ကို ပြန်တွက်ပေးတဲ့ Function
  void _calculateLiter(String value) {
    double amount = double.tryParse(value) ?? 0;
    _literController.text = (amount / pricePerLiter).toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sale Entry (ရောင်းရငွေစာရင်းသွင်းရန်)")),
      body: Row(
        children: [
          // ၁။ ဘယ်ဘက်ခြမ်း - Entry Form
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "အသေးစိတ်အချက်အလက်များ",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Grade ရွေးရန်
                      DropdownButtonFormField<String>(
                        value: selectedGrade,
                        decoration: const InputDecoration(labelText: "ဆီအမျိုးအစား (Grade)"),
                        items: [
                          '92 Ron',
                          '95 Ron',
                          'Premium Diesel',
                          'Diesel',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => selectedGrade = val),
                      ),

                      const SizedBox(height: 20),

                      // Liter ထည့်ရန်
                      TextField(
                        controller: _literController,
                        decoration: const InputDecoration(
                          labelText: "လီတာ (Liter)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _calculateAmount,
                      ),

                      const SizedBox(height: 20),

                      // Amount ထည့်ရန်
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: "ကျသင့်ငွေ (Amount)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _calculateLiter,
                      ),

                      const Spacer(),

                      // သိမ်းမည့်ခလုတ်
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            // သိမ်းမည့် Logic
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text(
                            "SAVE SALE RECORD",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ၂။ ညာဘက်ခြမ်း - Recent Sales List
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "လတ်တလောရောင်းရမှုများ (Recent Sales)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5, // နမူနာ ၅ ခု
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.local_gas_station)),
                            title: Text("92 Ron - 10.550 Liters"),
                            subtitle: const Text("2024-05-20 10:30 AM"),
                            trailing: const Text(
                              "26,375 MMK",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        );
                      },
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
}

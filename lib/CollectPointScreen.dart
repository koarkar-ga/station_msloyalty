import 'package:flutter/material.dart';

class CollectPointScreen extends StatefulWidget {
  const CollectPointScreen({super.key});

  @override
  State<CollectPointScreen> createState() => _CollectPointScreenState();
}

class _CollectPointScreenState extends State<CollectPointScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String memberName = "-";
  String currentPoints = "0";
  double earnedPoints = 0.0;

  // Amount ရိုက်လိုက်ရင် Point ကို တွက်ပေးမည့် Logic (ဥပမာ: ၁၀၀၀ ဖိုး = ၁ မှတ်)
  void _calculatePoints(String value) {
    double amount = double.tryParse(value) ?? 0;
    setState(() {
      earnedPoints = amount / 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Member Point Collection (ပွိုင့်စုရန်)")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ၁။ ဘယ်ဘက်ခြမ်း - Member Search & Point Entry
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        "Member ရှာဖွေရန်",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: "ဖုန်းနံပါတ် သို့မဟုတ် Card ID ရိုက်ပါ",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () => print("Opening Scanner..."),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: "ရောင်းရငွေ (Amount)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _calculatePoints,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "ရရှိမည့်ပွိုင့်: ${earnedPoints.toStringAsFixed(1)} Points",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_task),
                          label: const Text("COLLECT POINTS"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ၂။ ညာဘက်ခြမ်း - Member Info Preview
            Expanded(
              flex: 1,
              child: Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                      const SizedBox(height: 15),
                      const Text(
                        "Member အချက်အလက်",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _buildInfoRow("အမည်:", memberName),
                      _buildInfoRow("လက်ရှိပွိုင့်:", "$currentPoints Points"),
                      _buildInfoRow("အဆင့်:", "Gold Member"),
                      const Spacer(),
                      const Text(
                        "နောက်ဆုံးစုခဲ့သည့်နေ့: 20-05-2024",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

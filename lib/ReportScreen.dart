import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Reports (အရောင်းအစီရင်ခံစာ)"),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () => print("Printing Report...")),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => print("Exporting to Excel..."),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ၁။ အပေါ်ပိုင်း - Summary Cards (ရောင်းရငွေ အနှစ်ချုပ်)
            Row(
              children: [
                _buildSummaryCard("Total Sales", "2,500,000 MMK", Icons.payments, Colors.green),
                _buildSummaryCard(
                  "Total Liters",
                  "1,250.50 L",
                  Icons.local_gas_station,
                  Colors.blue,
                ),
                _buildSummaryCard("New Members", "12", Icons.group_add, Colors.orange),
                _buildSummaryCard("Points Issued", "2,500", Icons.stars, Colors.purple),
              ],
            ),
            const SizedBox(height: 25),

            // ၂။ အလယ်ပိုင်း - Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Text("Filter by Date:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () {}, // Date Picker logic
                      icon: const Icon(Icons.calendar_month),
                      label: Text("${selectedDate.toLocal()}".split(' ')[0]),
                    ),
                    const Spacer(),
                    ElevatedButton(onPressed: () {}, child: const Text("View Report")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ၃။ အောက်ပိုင်း - Data Table (အရောင်းစာရင်းဇယား)
            Expanded(
              child: Card(
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.blueGrey[50]),
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Grade')),
                        DataColumn(label: Text('Liters')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Member')),
                      ],
                      rows: List.generate(
                        10,
                        (index) => DataRow(
                          cells: [
                            DataCell(Text('10:${index}0 AM')),
                            DataCell(Text(index % 2 == 0 ? '92 Ron' : '95 Ron')),
                            DataCell(Text('25.00 L')),
                            DataCell(Text('62,500 MMK')),
                            DataCell(Text(index % 3 == 0 ? 'U Mya' : '-')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Card ဆောက်တဲ့ Helper Function
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

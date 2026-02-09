import 'package:flutter/material.dart';

class SummaryView extends StatefulWidget {
  final Widget saleSummaryTable;
  final Widget fuelSummaryTable;
  const SummaryView({Key? key, required this.saleSummaryTable, required this.fuelSummaryTable})
    : super(key: key);
  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  bool isTypeExpanded = true;
  bool isFuelExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table 1: Sale Type
        Flexible(
          flex: isTypeExpanded ? 1 : 0, // ပိတ်ထားရင် နေရာမယူတော့ဘူး
          child: _buildPanel(
            tileColor: Colors.redAccent.shade700,
            title: Row(
              children: [
                const Icon(Icons.summarize, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  "အရောင်းအမျိုးအစားအလိုက် အနှစ်ချုပ်",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            isExpanded: isTypeExpanded,
            onToggle: () => setState(() => isTypeExpanded = !isTypeExpanded),
            child: widget.saleSummaryTable,
          ),
        ),

        SizedBox(width: 10),

        // Table 2: Fuel Grade
        Flexible(
          flex: isFuelExpanded ? 1 : 0,
          child: _buildPanel(
            tileColor: Colors.blue.shade900,
            title: Row(
              children: [
                const Icon(
                  Icons.local_gas_station,
                  color: Colors.white,
                ), // ဆီဆိုင် icon ပြောင်းထားသည်
                const SizedBox(width: 10),
                const Text(
                  "ဆီအမျိုးအစားအလိုက် အနှစ်ချုပ်",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            isExpanded: isFuelExpanded,
            onToggle: () => setState(() => isFuelExpanded = !isFuelExpanded),
            child: widget.fuelSummaryTable,
          ),
        ),
      ],
    );
  }

  Widget _buildPanel({
    required Widget title,
    required Color tileColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Expanded(
      child: Column(
        children: [
          ListTile(
            tileColor: tileColor,
            title: title,
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: onToggle,
          ),
          if (isExpanded) child,
        ],
      ),
    );
  }
}

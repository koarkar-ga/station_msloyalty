import 'package:flutter/material.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class SummaryView extends StatefulWidget {
  final Widget saleSummaryTable;
  final Widget fuelSummaryTable;
  const SummaryView({
    super.key,
    required this.saleSummaryTable,
    required this.fuelSummaryTable,
  });
  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  bool isTypeExpanded = true;
  bool isFuelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table 1: Sale Type
          _buildPanel(
            accentColor: Colors.orangeAccent,
            icon: Icons.summarize_rounded,
            title: "Sales Summary",
            isExpanded: isTypeExpanded,
            onToggle: () => setState(() => isTypeExpanded = !isTypeExpanded),
            child: widget.saleSummaryTable,
            context: context,
          ),

          const SizedBox(width: 20),

          // Table 2: Fuel Grade
          _buildPanel(
            accentColor: Colors.blueAccent,
            icon: Icons.local_gas_station_rounded,
            title: "Fuel Summary",
            isExpanded: isFuelExpanded,
            onToggle: () => setState(() => isFuelExpanded = !isFuelExpanded),
            child: widget.fuelSummaryTable,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              opacity: 0.1,
              borderRadius: 16,
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : StyleConstants.lightText,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

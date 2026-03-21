import 'package:flutter/material.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class SummaryView extends StatefulWidget {
  final Widget saleSummaryTable;
  final Widget fuelSummaryTable;
  final Widget? stationSummaryTable;
  const SummaryView({
    super.key,
    required this.saleSummaryTable,
    required this.fuelSummaryTable,
    this.stationSummaryTable,
  });
  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  bool isTypeExpanded = false;
  bool isFuelExpanded = false;
  bool isStationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 750;
        
        final children = [
          // Table 1: Sale Type
          _buildPanel(
            accentColor: Colors.orangeAccent,
            icon: Icons.summarize_rounded,
            title: "Sales Summary",
            isExpanded: isTypeExpanded,
            onToggle: () => setState(() => isTypeExpanded = !isTypeExpanded),
            child: widget.saleSummaryTable,
            context: context,
            isMobile: isMobile,
          ),

          if (!isMobile) const SizedBox(width: 20) else const SizedBox(height: 20),

          // Table 2: Fuel Grade
          _buildPanel(
            accentColor: Colors.blueAccent,
            icon: Icons.local_gas_station_rounded,
            title: "Fuel Summary",
            isExpanded: isFuelExpanded,
            onToggle: () => setState(() => isFuelExpanded = !isFuelExpanded),
            child: widget.fuelSummaryTable,
            context: context,
            isMobile: isMobile,
          ),

          if (widget.stationSummaryTable != null) ...[
            if (!isMobile) const SizedBox(width: 20) else const SizedBox(height: 20),
            
            // Table 3: Station Summary
            _buildPanel(
              accentColor: Colors.greenAccent,
              icon: Icons.location_city_rounded,
              title: "Station Summary",
              isExpanded: isStationExpanded,
              onToggle: () => setState(() => isStationExpanded = !isStationExpanded),
              child: widget.stationSummaryTable!,
              context: context,
              isMobile: isMobile,
            ),
          ],
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: isMobile 
            ? Column(children: children)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
        );
      },
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
    required bool isMobile,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final panelContent = Column(
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
                primary: false,
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  child: child,
                ),
              ),
            ),
          ],
        ],
      );
    return isMobile ? panelContent : Expanded(child: panelContent);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Services/FetchUserNameCache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class LoyaltyReportScreen extends StatefulWidget {
  const LoyaltyReportScreen({super.key});

  @override
  State<LoyaltyReportScreen> createState() => _LoyaltyReportScreenState();
}

class _LoyaltyReportScreenState extends State<LoyaltyReportScreen> {
  final supabase = Supabase.instance.client;

  // Date picker state for Points Collected Tab
  DateTime _pointsStartDate = DateTime.now();
  DateTime _pointsEndDate = DateTime.now();

  // Date picker state for Rewards Claimed Tab
  DateTime _rewardsStartDate = DateTime.now();
  DateTime _rewardsEndDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: MsAppBar(
          title: "Loyalty Reports",
          showBackButton: true,
          bottom: TabBar(
            labelColor: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
            indicatorColor: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.stars), text: "Points Collected"),
              Tab(icon: Icon(Icons.card_giftcard), text: "Rewards Claimed"),
            ],
          ),
        ),
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
          child: TabBarView(
            children: [_buildPointsCollectedTab(context), _buildRewardsClaimedTab(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCollectedTab(BuildContext context) {
    final startISO = DateTime(_pointsStartDate.year, _pointsStartDate.month, _pointsStartDate.day, 0, 0, 0).toIso8601String();
    final endISO = DateTime(_pointsEndDate.year, _pointsEndDate.month, _pointsEndDate.day, 23, 59, 59).toIso8601String();

    final isMobile = MediaQuery.of(context).size.width < 750;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: isMobile
          ? ListView(
              children: [
                _buildGlassDatePickerRow(
                  label: "Points Collection History",
                  startDate: _pointsStartDate,
                  endDate: _pointsEndDate,
                  onStartPicked: (date) => setState(() => _pointsStartDate = date),
                  onEndPicked: (date) => setState(() => _pointsEndDate = date),
                  onExport: () => _exportToExcel(_pointsStartDate, _pointsEndDate),
                  context: context,
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: _buildPointsDataTable(startISO, endISO),
                ),
              ],
            )
          : Column(
              children: [
                _buildGlassDatePickerRow(
                  label: "Points Collection History",
                  startDate: _pointsStartDate,
                  endDate: _pointsEndDate,
                  onStartPicked: (date) => setState(() => _pointsStartDate = date),
                  onEndPicked: (date) => setState(() => _pointsEndDate = date),
                  onExport: () => _exportToExcel(_pointsStartDate, _pointsEndDate),
                  context: context,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: _buildPointsDataTable(startISO, endISO),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRewardsClaimedTab(BuildContext context) {
    final startISO = DateTime(_rewardsStartDate.year, _rewardsStartDate.month, _rewardsStartDate.day, 0, 0, 0).toIso8601String();
    final endISO = DateTime(_rewardsEndDate.year, _rewardsEndDate.month, _rewardsEndDate.day, 23, 59, 59).toIso8601String();

    final isMobile = MediaQuery.of(context).size.width < 750;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: isMobile
          ? ListView(
              children: [
                _buildGlassDatePickerRow(
                  label: "Rewards Redemption History",
                  startDate: _rewardsStartDate,
                  endDate: _rewardsEndDate,
                  onStartPicked: (date) => setState(() => _rewardsStartDate = date),
                  onEndPicked: (date) => setState(() => _rewardsEndDate = date),
                  onExport: () => _exportToExcel(_rewardsStartDate, _rewardsEndDate),
                  context: context,
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  child: _buildRewardsDataTable(startISO, endISO),
                ),
              ],
            )
          : Column(
              children: [
                _buildGlassDatePickerRow(
                  label: "Rewards Redemption History",
                  startDate: _rewardsStartDate,
                  endDate: _rewardsEndDate,
                  onStartPicked: (date) => setState(() => _rewardsStartDate = date),
                  onEndPicked: (date) => setState(() => _rewardsEndDate = date),
                  onExport: () => _exportToExcel(_rewardsStartDate, _rewardsEndDate),
                  context: context,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: _buildRewardsDataTable(startISO, endISO),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGlassDatePickerRow({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    required Function(DateTime) onStartPicked,
    required Function(DateTime) onEndPicked,
    required VoidCallback onExport,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 750;

    return GlassContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      borderRadius: 16,
      child: Wrap(
        alignment: isMobile ? WrapAlignment.center : WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
              color: isDark ? Colors.white : StyleConstants.lightText,
              letterSpacing: 1.2,
            ),
          ),
          if (isMobile) const SizedBox(width: double.infinity, height: 0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dateButton(
                isMobile 
                  ? DateFormat('dd MMM').format(startDate)
                  : "FROM: ${DateFormat('dd MMM yyyy').format(startDate)}",
                () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) onStartPicked(picked);
                },
                context,
              ),
              _dateButton(
                isMobile 
                  ? DateFormat('dd MMM').format(endDate)
                  : "TO: ${DateFormat('dd MMM yyyy').format(endDate)}",
                () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) onEndPicked(picked);
                },
                context,
              ),
              ElevatedButton.icon(
                onPressed: onExport,
                icon: Icon(Icons.download_rounded, size: isMobile ? 16 : 18),
                label: Text(
                  isMobile ? "EXPORT" : "EXPORT EXCEL",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String text, VoidCallback onPressed, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 750;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? StyleConstants.darkAccent : StyleConstants.lightAccent),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPointsData(String startISO, String endISO) async {
    final response = await supabase
        .from('fuel_transactions')
        .select()
        .eq('station_id', AppConfig.stationId)
        .gte('created_at', startISO)
        .lte('created_at', endISO)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
    for (var row in data) {
      if (row['user_id'] != null) {
        row['user_name'] = await fetchUserName(row['user_id']);
      } else {
        row['user_name'] = 'Unknown';
      }
    }
    return data;
  }

  Widget _buildPointsDataTable(String startISO, String endISO) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPointsData(startISO, endISO),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));

        final data = snapshot.data ?? [];
        if (data.isEmpty) return const Center(child: Text("No records found"));

        return Column(
          children: [
            _buildInternalSummary(data, context),
            const SizedBox(height: 16),
            isMobile 
              ? _buildPointsCardList(data)
              : Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowMaxHeight: 60,
                          columns: [
                            _tblHeader("No"),
                            _tblHeader("User"),
                            _tblHeader("Voucher"),
                            _tblHeader("Date"),
                            _tblHeader("Points"),
                            _tblHeader("Fuel"),
                            _tblHeader("Amount"),
                          ],
                          rows: List.generate(data.length, (index) {
                            final row = data[index];
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(row['user_name'] ?? '-')),
                                DataCell(Text(row['voc_no'] ?? '-')),
                                DataCell(Text(row['created_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(row['created_at']).toLocal()) : '-')),
                                DataCell(Text('+${row['points_earned']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                DataCell(Text(row['fuel_type'] ?? '-')),
                                DataCell(Text(formatter.format(row['amount_mmk'] ?? 0))),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointsCardList(List<Map<String, dynamic>> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("#${index + 1}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("+${row['points_earned']} PTS", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _reportRow(Icons.person, "User", row['user_name'] ?? '-'),
                _reportRow(Icons.receipt, "Voucher", row['voc_no'] ?? '-'),
                _reportRow(Icons.calendar_today, "Date", row['created_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(row['created_at']).toLocal()) : '-'),
                _reportRow(Icons.local_gas_station, "Fuel", row['fuel_type'] ?? '-'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Amount Paid", style: TextStyle(color: Colors.grey)),
                    Text("${formatter.format(row['amount_mmk'] ?? 0)} MMK", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  DataColumn _tblHeader(String label) {
    return DataColumn(label: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)));
  }

  Widget _buildInternalSummary(List<Map<String, dynamic>> data, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 750;
    double totalPts = data.fold(0, (sum, item) => sum + (item['points_earned'] ?? 0));
    double totalMmk = data.fold(0, (sum, item) => sum + (item['amount_mmk'] ?? 0));

    if (isMobile) {
      return Column(
        children: [
          _sumTile("TOTAL POINTS EARNED", "${formatter.format(totalPts)} PTS", Colors.green, context),
          const SizedBox(height: 12),
          _sumTile("TOTAL REVENUE", "${formatter.format(totalMmk)} MMK", Colors.blue, context),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _sumTile("TOTAL POINTS EARNED", "${formatter.format(totalPts)} PTS", Colors.green, context)),
        const SizedBox(width: 16),
        Expanded(child: _sumTile("TOTAL REVENUE", "${formatter.format(totalMmk)} MMK", Colors.blue, context)),
      ],
    );
  }

  Widget _sumTile(String title, String value, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRewardsData(String startISO, String endISO) async {
    final response = await supabase
        .from('redemption_history')
        .select()
        .eq('station_id', AppConfig.stationId)
        .gte('created_at', startISO)
        .lte('created_at', endISO)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
    for (var row in data) {
      row['user_name'] = row['user_id'] != null ? await fetchUserName(row['user_id']) : 'Unknown';
      row['reward_title'] = row['reward_id'] != null ? await getRewardTitle(row['reward_id']) : 'Unknown Item';
    }
    return data;
  }

  Widget _buildRewardsDataTable(String startISO, String endISO) {
    final isMobile = MediaQuery.of(context).size.width < 750;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRewardsData(startISO, endISO),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));

        final data = snapshot.data ?? [];
        if (data.isEmpty) return const Center(child: Text("No records found"));

        double totalSpent = data.fold(0, (sum, item) => sum + (item['points_spent'] ?? 0));

        return Column(
          children: [
            _sumTile("TOTAL POINTS REDEEMED", "${formatter.format(totalSpent)} PTS", Colors.orange, context),
            const SizedBox(height: 16),
            isMobile 
              ? _buildRewardsCardList(data)
              : Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: [
                            _tblHeader("No"),
                            _tblHeader("User"),
                            _tblHeader("Reward Item"),
                            _tblHeader("Date"),
                            _tblHeader("Points Spent"),
                          ],
                          rows: List.generate(data.length, (index) {
                            final row = data[index];
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(row['user_name'] ?? '-')),
                                DataCell(Text(row['reward_title'] ?? '-')),
                                DataCell(Text(row['created_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(row['created_at']).toLocal()) : '-')),
                                DataCell(Text('-${row['points_spent']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRewardsCardList(List<Map<String, dynamic>> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("#${index + 1}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("-${row['points_spent']} PTS", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _reportRow(Icons.person, "User", row['user_name'] ?? '-'),
                _reportRow(Icons.card_giftcard, "Reward", row['reward_title'] ?? '-'),
                _reportRow(Icons.calendar_today, "Date", row['created_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(row['created_at']).toLocal()) : '-'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportToExcel(DateTime start, DateTime end) async {
    try {
      final startISO = DateTime(start.year, start.month, start.day, 0, 0, 0).toIso8601String();
      final endISO = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
      final data = await _fetchPointsData(startISO, endISO);

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export")));
        return;
      }

      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Loyalty Report";

      // Simple Export Logic
      sheet.getRangeByIndex(1, 1).setText("No");
      sheet.getRangeByIndex(1, 2).setText("User");
      sheet.getRangeByIndex(1, 3).setText("Voucher");
      sheet.getRangeByIndex(1, 4).setText("Points");

      for (int i = 0; i < data.length; i++) {
        sheet.getRangeByIndex(i + 2, 1).setNumber(i + 1.0);
        sheet.getRangeByIndex(i + 2, 2).setText(data[i]['user_name'] ?? '-');
        sheet.getRangeByIndex(i + 2, 3).setText(data[i]['voc_no'] ?? '-');
        sheet.getRangeByIndex(i + 2, 4).setNumber(double.tryParse(data[i]['points_earned'].toString()) ?? 0);
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/Loyalty_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved to Documents"), action: SnackBarAction(label: 'Open', onPressed: () => OpenFile.open(path))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export Error: $e")));
    }
  }
}

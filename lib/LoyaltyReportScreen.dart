import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Services/FetchUserNameCache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const MsAppBar(title: "Loyalty Reports"),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.orangeAccent,
            tabs: [
              Tab(icon: Icon(Icons.stars), text: "Points Collected (ရယူမှု)"),
              Tab(icon: Icon(Icons.card_giftcard), text: "Rewards Claimed (ထုတ်ယူမှု)"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildPointsCollectedTab(), _buildRewardsClaimedTab()]),
      ),
    );
  }

  // --- Points Collected Tab ---
  Widget _buildPointsCollectedTab() {
    final startISO = DateTime(
      _pointsStartDate.year,
      _pointsStartDate.month,
      _pointsStartDate.day,
      0,
      0,
      0,
    ).toIso8601String();
    final endISO = DateTime(
      _pointsEndDate.year,
      _pointsEndDate.month,
      _pointsEndDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    return Column(
      children: [
        _buildDatePickerRow(
          label: "ရက်စွဲရွေးချယ်ရန်",
          startDate: _pointsStartDate,
          endDate: _pointsEndDate,
          onStartPicked: (date) => setState(() => _pointsStartDate = date),
          onEndPicked: (date) => setState(() => _pointsEndDate = date),
        ),
        // Future Data Table
        Expanded(child: _buildPointsDataTable(startISO, endISO)),
      ],
    );
  }

  // --- Rewards Claimed Tab ---
  Widget _buildRewardsClaimedTab() {
    final startISO = DateTime(
      _rewardsStartDate.year,
      _rewardsStartDate.month,
      _rewardsStartDate.day,
      0,
      0,
      0,
    ).toIso8601String();
    final endISO = DateTime(
      _rewardsEndDate.year,
      _rewardsEndDate.month,
      _rewardsEndDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    return Column(
      children: [
        _buildDatePickerRow(
          label: "ရက်စွဲရွေးချယ်ရန်",
          startDate: _rewardsStartDate,
          endDate: _rewardsEndDate,
          onStartPicked: (date) => setState(() => _rewardsStartDate = date),
          onEndPicked: (date) => setState(() => _rewardsEndDate = date),
        ),
        // Future Data Table
        Expanded(child: _buildRewardsDataTable(startISO, endISO)),
      ],
    );
  }

  // Common Header/Date Picker Row
  Widget _buildDatePickerRow({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    required Function(DateTime) onStartPicked,
    required Function(DateTime) onEndPicked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              _dateButton("From: ${DateFormat('dd-MM-yyyy').format(startDate)}", () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onStartPicked(picked);
              }),
              const SizedBox(width: 10),
              _dateButton("To: ${DateFormat('dd-MM-yyyy').format(endDate)}", () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) onEndPicked(picked);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateButton(String text, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blueGrey,
        side: const BorderSide(color: Colors.blueGrey),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPointsData(startISO, endISO),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }

        final data = snapshot.data ?? [];

        // Calculate Summary
        double totalPoints = data.fold(0, (sum, item) => sum + (item['points_earned'] ?? 0));

        return Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    "ပေးလိုက်ရသော ပွိုင့်စုစုပေါင်း: ${formatter.format(totalPoints)} Pts",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Table
            Expanded(
              child: data.isEmpty
                  ? const Center(child: Text("မှတ်တမ်းမရှိပါ"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.green.withOpacity(0.1)),
                          columns: const [
                            DataColumn(
                              label: Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text(
                                'User Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Voucher No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date & Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Points Earned',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: List.generate(data.length, (index) {
                            final row = data[index];
                            final userName = row['user_name'] ?? 'Unknown';
                            final dateStr = row['created_at'] != null
                                ? DateFormat(
                                    'dd-MM-yy HH:mm a',
                                  ).format(DateTime.parse(row['created_at']))
                                : '-';

                            return DataRow(
                              color: MaterialStateProperty.all(
                                index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              ),
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(userName)),
                                DataCell(Text('${row['voc_no'] ?? '-'}')),
                                DataCell(Text(dateStr)),
                                DataCell(
                                  Text(
                                    '+${row['points_earned']} Pts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
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
    Map<int, String> rewardCache = {};

    for (var row in data) {
      // Fetch User Name
      if (row['user_id'] != null) {
        row['user_name'] = await fetchUserName(row['user_id']);
      } else {
        row['user_name'] = 'Unknown';
      }

      // Fetch Reward Title
      if (row['reward_id'] != null) {
        int rId = row['reward_id'];
        if (!rewardCache.containsKey(rId)) {
          rewardCache[rId] = await getRewardTitle(rId);
        }
        row['reward_title'] = rewardCache[rId];
      } else {
        row['reward_title'] = 'Unknown Item';
      }
    }
    return data;
  }

  Widget _buildRewardsDataTable(String startISO, String endISO) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRewardsData(startISO, endISO),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Fallback if relations fail
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                Text(
                  "Query Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? [];

        // Calculate Summary
        double totalPointsSpent = data.fold(0, (sum, item) => sum + (item['points_spent'] ?? 0));

        return Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.orange),
                  const SizedBox(width: 10),
                  Text(
                    "လဲလှယ်ထားသော ပွိုင့်စုစုပေါင်း: ${formatter.format(totalPointsSpent)} Pts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Table
            Expanded(
              child: data.isEmpty
                  ? const Center(child: Text("မှတ်တမ်းမရှိပါ"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.orange.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text(
                                'User Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Reward Item',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date & Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Points Spent',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: List.generate(data.length, (index) {
                            final row = data[index];
                            final userName = row['user_name'] ?? 'Unknown';
                            final rewardTitle = row['reward_title'] ?? 'Unknown Item';
                            final dateStr = row['created_at'] != null
                                ? DateFormat(
                                    'dd-MM-yy HH:mm a',
                                  ).format(DateTime.parse(row['created_at']))
                                : '-';

                            return DataRow(
                              color: MaterialStateProperty.all(
                                index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              ),
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(Text(userName)),
                                DataCell(Text(rewardTitle)),
                                DataCell(Text(dateStr)),
                                DataCell(
                                  Text(
                                    '-${row['points_spent']} Pts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

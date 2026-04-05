import 'package:flutter/material.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Helper/DuplicateAnalysisHelper.dart';
import 'package:station_msloyalty/Helper/DuplicateExcelExport.dart';

class DuplicateAnalysisScreen extends StatefulWidget {
  final List<dynamic> salesData;

  const DuplicateAnalysisScreen({super.key, required this.salesData});

  @override
  State<DuplicateAnalysisScreen> createState() => _DuplicateAnalysisScreenState();
}

class _DuplicateAnalysisScreenState extends State<DuplicateAnalysisScreen> {
  late List<Map<String, dynamic>> _analyzedData;
  bool _isLoading = true;
  bool _excludeSpecialPrefixes = false;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() {
    setState(() => _isLoading = true);
    _analyzedData = DuplicateAnalysisHelper.analyzeDuplicates(
      widget.salesData,
      excludePrefixes: _excludeSpecialPrefixes ? ['C', 'CC', 'CY'] : null,
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 1100;

    // Calculate stats for Sudanese Summary
    int suspiciousCount =
        _analyzedData.where((e) => e['is_suspicious'] == true).length;
    int crossStationCount = _analyzedData
        .where((e) =>
            e['suspicious_reason']?.toString().contains('Station မတူပဲ') ??
            false)
        .length;
    int diffFuelCount = _analyzedData
        .where((e) =>
            e['suspicious_reason']?.toString().contains('Fuel Type လွှဲနေ') ??
            false)
        .length;

    return Scaffold(
      backgroundColor: isDark ? StyleConstants.darkBg : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Duplicate Analysis Report"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performAnalysis,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isMobile
              ? _buildMobileView(
                  isDark, suspiciousCount, crossStationCount, diffFuelCount)
              : _buildDesktopView(
                  isDark, suspiciousCount, crossStationCount, diffFuelCount),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => exportDuplicateAnalysis(_analyzedData),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        label: const Text("Export to Excel",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- Layout Views ---

  Widget _buildMobileView(
      bool isDark, int suspicious, int crossStation, int diffFuel) {
    return Column(
      children: [
        _buildPrefixFilter(isDark),
        _buildBurmeseSummary(isDark, suspicious, crossStation, diffFuel),
        _buildResultCountHeader(),
        Expanded(
          child: _analyzedData.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _analyzedData.length,
                  itemBuilder: (context, index) {
                    final record = _analyzedData[index];
                    return _buildAnalysisCard(record, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopView(
      bool isDark, int suspicious, int crossStation, int diffFuel) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: _buildPrefixFilter(isDark),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildBurmeseSummary(isDark, suspicious, crossStation, diffFuel),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildResultCountHeader(),
            ),
            Expanded(
              child: _analyzedData.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 8),
                      itemCount: _analyzedData.length,
                      itemBuilder: (context, index) {
                        final record = _analyzedData[index];
                        return _buildAnalysisCard(record, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCountHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            "Analyzed ${_analyzedData.length} records of duplicated vehicles",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefixFilter(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: CheckboxListTile(
        title: const Text(
          "C, CC, CY ယာဉ်များကို ဖယ်ထုတ်ရန်",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "Exclude vehicles with common prefixes",
          style: TextStyle(fontSize: 11),
        ),
        value: _excludeSpecialPrefixes,
        activeColor: Colors.teal,
        onChanged: (val) {
          setState(() {
            _excludeSpecialPrefixes = val ?? false;
          });
          _performAnalysis();
        },
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildBurmeseSummary(bool isDark, int suspicious, int crossStation, int diffFuel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? StyleConstants.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                "တင်ပြချက်",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.orange : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryText("၁။ ကားနံပါတ်တစ်ခုတည်းဖြင့် ဆီအမျိုးအစား မတူညီဘဲ ထပ်ခါတလဲလဲ ဖြည့်ထားမှု ($diffFuel) ခု တွေ့ရှိရပါသည်။"),
          const SizedBox(height: 8),
          _summaryText("၂။ မတူညီသော ဆိုင်ခွဲများတွင် တစ်ရက်တည်းအတွင်း သွားရောက်ဖြည့်တင်းမှု ($crossStation) ခု တွေ့ရှိရပါသည်။"),
          const SizedBox(height: 8),
          _summaryText("၃။ ယခု Report တွင် စုစုပေါင်း သံသယဖြစ်ဖွယ် အချက်ပေါင်း ($suspicious) ခုကို ဖော်ထုတ်ပေးထားပါသည်။"),
          const SizedBox(height: 12),
          Text(
            "* Excel Export ထုတ်ယူခြင်းဖြင့် အသေးစိတ်နှင့် အရောင်များဖြင့် ခွဲခြားကြည့်ရှုနိုင်ပါသည်။",
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _summaryText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> record, bool isDark) {
    final isSuspicious = record['is_suspicious'] == true;
    final String timeInterval = record['analysis_time_diff'] ?? '-';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSuspicious 
          ? const BorderSide(color: Colors.redAccent, width: 1.5)
          : BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          if (isSuspicious)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              width: double.infinity,
              color: Colors.redAccent.withOpacity(0.1),
              child: Text(
                "🚩 ${record['suspicious_reason']}",
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record['Vehical_No'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "Invoice: ${record['VocNo']}",
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${record['SALELITER']} L",
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record['FuelTypeName'] ?? '-',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      record['station_name'] ?? '-',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      record['S_Date'] ?? '-',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                if (timeInterval != "-") ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          "Interval: $timeInterval after previous refill",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No suspicious duplicates detected", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("Great! All vehicles seem consistent.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

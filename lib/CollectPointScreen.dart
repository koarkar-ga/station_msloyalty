import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Helper/BuildProgessOverlay.dart';
import 'package:station_msloyalty/Helper/BuildRecentCollectedPanel.dart';
import 'package:station_msloyalty/Helper/DataCell.dart';
import 'package:station_msloyalty/Helper/FetchWithProgress.dart';
import 'package:station_msloyalty/Helper/MsAppBar.dart';
import 'package:station_msloyalty/Helper/TextFieldDialog.dart';
import 'package:station_msloyalty/Model/BuildFuelTypeChip.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';
import 'package:station_msloyalty/Model/SaleTypeModel.dart';
import 'package:station_msloyalty/Services/CheckVocNoExists.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_msloyalty/Helper/CameraScannerDialog.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';

class CollectPointScreen extends StatefulWidget {
  const CollectPointScreen({super.key});

  @override
  State<CollectPointScreen> createState() => _CollectPointScreenState();
}

class _CollectPointScreenState extends State<CollectPointScreen> {
  List<dynamic> localDataList = [];
  final StreamController<SalesLoadStatus> _localStreamController =
      StreamController<SalesLoadStatus>.broadcast();

  @override
  void initState() {
    super.initState();
    fetchPointSales();
  }

  Future<void> fetchPointSales() async {
    _localStreamController.add(
      SalesLoadStatus(data: [], progress: 0.0, isLoading: true),
    );
    localDataList.clear();
    try {
      String lastRecentSalesUrl = "${AppConfig.apiUrl}/api/sales/recent";
      await fetchWithProgress(
        lastRecentSalesUrl,
        localDataList,
        _localStreamController,
      );
    } catch (e) {
      _localStreamController.add(
        SalesLoadStatus(data: [], progress: 0.0, isLoading: false),
      );
    } finally {
      // final success status is already emitted by fetchWithProgress onDone.
    }
  }

  @override
  void dispose() {
    _localStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const MsAppBar(title: 'Customer Details', showBackButton: true),
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
        child: Row(
          children: [
            Expanded(
              child: StreamBuilder<SalesLoadStatus>(
                stream: _localStreamController.stream,
                builder: (context, snapshot) {
                  final status =
                      snapshot.data ??
                      SalesLoadStatus(data: [], progress: 0.0, isLoading: true);
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildGlassHeader(context),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GlassContainer(
                                child: ListView.builder(
                                  itemCount: status.data.length,
                                  itemBuilder: (context, index) =>
                                      _buildDataRow(
                                        status.data[index],
                                        index,
                                        context,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status.isLoading)
                        buildProgressOverlay(
                          status.progress,
                          status.data.length,
                        ),
                      Positioned(
                        bottom: 40,
                        right: 40,
                        child: FloatingActionButton(
                          backgroundColor: isDark
                              ? StyleConstants.darkAccent
                              : StyleConstants.lightAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          onPressed: () => fetchPointSales(),
                          child: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Right Panel
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: SizedBox(
                width: 380,
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildRightPanelHeader(context),
                      Expanded(child: buildRecentCollectedPanel()),
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

  Widget _buildGlassHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      borderRadius: 16,
      child: Row(
        children: [
          _headerCell("SR", 40, isCenter: true),
          _headerCell("VOUCHER NO", 150, isCenter: true),
          _headerCell("DATE & TIME", 180, isCenter: true),
          _headerCell("FUEL TYPE", 140, isCenter: true),
          _headerCell("LITER", 80, isCenter: true),
          _headerCell("AMOUNT (MMK)", 120, isCenter: true),
          _headerCell("SALE TYPE", 120, isCenter: true),
          Expanded(child: _headerCell("STATUS", 0, isCenter: true)),
        ],
      ),
    );
  }

  Widget _buildRightPanelHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: isDark
                ? StyleConstants.darkAccent
                : StyleConstants.lightAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            "RECENTLY COLLECTED",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, {bool isCenter = false}) {
    return SizedBox(
      width: width == 0 ? null : width,
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildDataRow(dynamic sale, int index, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          _dataCellText("${index + 1}", 40, isCenter: true, context: context),
          _dataCellText(
            "${sale['VocNo']}",
            150,
            isBold: true,
            isCenter: true,
            context: context,
          ),
          _dataCellText(
            DateFormat('dd-MM-yy HH:mm').format(DateTime.parse(sale['S_Date'])),
            180,
            fontSize: 13,
            isCenter: true,
            context: context,
          ),
          dataCell(
            sale['FuelTypeName'] ?? '-',
            140,
            showRightBorder: false,
            cardColor: getFuelColor(sale['FuelTypeName'] ?? ''),
            alignment: Alignment.center,
          ),
          _dataCellText(
            "${sale['SALELITER']}",
            80,
            isBold: true,
            isCenter: true,
            context: context,
          ),
          _dataCellText(
            formatter.format(sale['TotalPrice']),
            120,
            isBold: true,
            isCenter: true,
            context: context,
          ),
          dataCell(
            "${sale['Sale_Type_name']}",
            120,
            cardColor: getSaleTypeColor(sale['Sale_Type_name'] ?? ''),
            showRightBorder: false,
            alignment: Alignment.center,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child:
                  (sale['Sale_Type_name'] == 'Cash Sale' ||
                      sale['Sale_Type_name'] == 'ePayment' ||
                      sale['Sale_Type_name'] == 'Credit Sale')
                  ? CheckAlreadyCollected(sale: sale)
                  : const Icon(
                      Icons.block_flipped,
                      size: 18,
                      color: Colors.redAccent,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCellText(
    String text,
    double width, {
    bool isBold = false,
    bool isCenter = false,
    double fontSize = 14,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: isDark ? Colors.white : StyleConstants.lightText,
        ),
      ),
    );
  }
}

class CheckAlreadyCollected extends StatefulWidget {
  final Map<String, dynamic> sale;
  const CheckAlreadyCollected({super.key, required this.sale});
  @override
  State<CheckAlreadyCollected> createState() => _CheckAlreadyCollectedState();
}

class _CheckAlreadyCollectedState extends State<CheckAlreadyCollected> {
  final supabase = Supabase.instance.client;
  bool _useCameraScanner = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useCameraScanner = prefs.getBool('use_camera_scanner') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String fullVocNo = "${AppConfig.stationId}${widget.sale['VocNo']}";
    return StreamBuilder<bool>(
      stream: checkIfExistsStream(fullVocNo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        if (snapshot.data == true)
          return const Icon(Icons.check_circle, color: Colors.green, size: 24);

        if (_useCameraScanner) {
          return CameraScannerDialog(
            supabase: supabase,
            vocNo: widget.sale['VocNo'],
            vehicalNo: widget.sale['Vehical_No'] ?? '',
            fuelType: widget.sale['FuelTypeName'] ?? '',
            amount: widget.sale['TotalPrice']?.toString() ?? '0',
            saleType: widget.sale['Sale_Type_name'] ?? '',
            unitPrice: double.tryParse(
              widget.sale['SalePrice']?.toString() ?? '0',
            ),
            saleLiter: double.tryParse(
              widget.sale['SALELITER']?.toString() ?? '0',
            ),
          );
        } else {
          return TextFieldDialog(
            supabase: supabase,
            voc_no: widget.sale['VocNo'],
            vehical_no: widget.sale['Vehical_No'] ?? '',
            fuel_type: widget.sale['FuelTypeName'] ?? '',
            amount: widget.sale['TotalPrice']?.toString() ?? '0',
            sale_type: widget.sale['Sale_Type_name'] ?? '',
            unit_price: double.tryParse(
              widget.sale['SalePrice']?.toString() ?? '0',
            ),
            sale_liter: double.tryParse(
              widget.sale['SALELITER']?.toString() ?? '0',
            ),
          );
        }
      },
    );
  }
}

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
import 'package:shimmer/shimmer.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/Model/OfflineTransaction.dart';
import 'package:isar/isar.dart';

class CollectPointScreen extends StatefulWidget {
  const CollectPointScreen({super.key});

  @override
  State<CollectPointScreen> createState() => _CollectPointScreenState();
}

class _CollectPointScreenState extends State<CollectPointScreen> {
  List<dynamic> localDataList = [];
  final StreamController<SalesLoadStatus> _localStreamController =
      StreamController<SalesLoadStatus>.broadcast();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<int> _offlineCount = ValueNotifier<int>(0);
  StreamSubscription? _offlineSubscription;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    fetchPointSales();
    _initOfflineListener();
  }

  void _initOfflineListener() {
    _updateOfflineCount();
    _offlineSubscription = AppConfig.isar.offlineTransactions.watchLazy().listen((_) {
      _updateOfflineCount();
    });
  }

  Future<void> _updateOfflineCount() async {
    final count = await AppConfig.isar.offlineTransactions
        .where()
        .isSyncedEqualTo(false)
        .count();
    _offlineCount.value = count;
  }

  Future<void> _syncOfflineData() async {
    if (_isSyncing) return;

    final offlineTxns = await AppConfig.isar.offlineTransactions
        .where()
        .isSyncedEqualTo(false)
        .findAll();
    if (offlineTxns.isEmpty) {
      BotToast.showText(text: "Sync လုပ်ရန် ဒေတာ မရှိပါ။");
      return;
    }

    setState(() => _isSyncing = true);
    BotToast.showText(text: "Syncing Offline Data...");
    BotToast.showLoading();

    int successCount = 0;
    int failCount = 0;

    final supabase = Supabase.instance.client;

    for (var tx in offlineTxns) {
      try {
        if (tx.actionType == OfflineActionType.earn) {
          final res = await supabase.rpc('add_fuel_points', params: {
            'target_user_id': tx.targetUid,
            'station_id': tx.stationId,
            'fuel_type': tx.fuelType,
            'amount_mmk': tx.amountMmk,
            'v_voc_no': tx.vocNo,
            'v_sale_type': tx.saleType,
            'v_vehicle_no': tx.vehicleNo,
            'v_payment_type': tx.paymentType,
            'v_unit_price': tx.unitPrice,
            'v_sale_liter': tx.saleLiter,
          });

          if (res['status'] == 'success') {
            if (tx.dynamicTokenId != null) {
              await supabase
                  .from('qr_tokens')
                  .update({'is_used': true}).eq('id', tx.dynamicTokenId!);
            }
            await AppConfig.isar.writeTxn(
                () => AppConfig.isar.offlineTransactions.delete(tx.id));
            successCount++;
          } else {
            throw res['message'] ?? 'Sync failed';
          }
        } else {
          // Redeem logic
          await supabase.rpc('process_reward_redemption', params: {
            'target_user_id': tx.targetUid,
            'target_reward_id': tx.rewardId,
            'required_points': tx.requiredPoints,
            'target_station_id': tx.stationId,
          });

          if (tx.dynamicTokenId != null) {
            await supabase
                .from('qr_tokens')
                .update({'is_used': true}).eq('id', tx.dynamicTokenId!);
          }
          await AppConfig.isar.writeTxn(
              () => AppConfig.isar.offlineTransactions.delete(tx.id));
          successCount++;
        }
      } catch (e) {
        failCount++;
        print("Sync Error for ID ${tx.id}: $e");
        tx.syncError = e.toString();
        await AppConfig.isar.writeTxn(
            () => AppConfig.isar.offlineTransactions.put(tx));
      }
    }

    BotToast.closeAllLoading();
    if (mounted) {
      setState(() => _isSyncing = false);
    }

    if (failCount == 0) {
      BotToast.showText(
          text: "Sync အောင်မြင်ပါသည်။ ($successCount records pushed)",
          contentColor: Colors.green);
    } else {
      BotToast.showText(
          text: "Sync ပြီးဆုံး - $successCount အောင်မြင်၊ $failCount မအောင်မြင်ပါ။",
          contentColor: Colors.orange);
    }
    
    // Refresh history
    fetchPointSales();
  }

  Widget _buildSyncBadge() {
    return ValueListenableBuilder<int>(
      valueListenable: _offlineCount,
      builder: (context, count, _) {
        if (count == 0 && !_isSyncing) return const SizedBox.shrink();

        return InkWell(
          onTap: _syncOfflineData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isSyncing ? Colors.blueAccent : Colors.orangeAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSyncing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.sync, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _isSyncing ? "Syncing..." : "$count Pending Scans",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    _searchController.dispose();
    _searchQuery.dispose();
    _offlineSubscription?.cancel();
    _offlineCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MsAppBar(
        title: 'Customer Details',
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: _buildSyncBadge()),
          ),
        ],
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 1100;

            final mainContent = StreamBuilder<SalesLoadStatus>(
              stream: _localStreamController.stream,
              builder: (context, snapshot) {
                final status =
                    snapshot.data ??
                    SalesLoadStatus(data: [], progress: 0.0, isLoading: true);
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 750;

                if (isMobile) {
                  return Stack(
                    children: [
                      // Sync Badge for Mobile
                      Positioned(
                        top: 10,
                        right: 16,
                        child: _buildSyncBadge(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 60.0, left: 16, right: 16, bottom: 16),
                        child: Column(
                          children: [
                            // --- Search Box with Suggestions ---
                            ValueListenableBuilder<String>(
                              valueListenable: _searchQuery,
                              builder: (context, query, _) {
                                final suggestions = status.data
                                    .map(
                                      (s) => s['Vehical_No']?.toString() ?? '',
                                    )
                                    .where((v) => v.isNotEmpty)
                                    .toSet()
                                    .toList();

                                return Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    return suggestions.where(
                                      (s) => s.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      ),
                                    );
                                  },
                                  onSelected: (selected) =>
                                      _searchQuery.value = selected,
                                  fieldViewBuilder:
                                      (
                                        context,
                                        controller,
                                        focusNode,
                                        onFieldSubmitted,
                                      ) {
                                        if (controller.text !=
                                                _searchQuery.value &&
                                            _searchQuery.value.isEmpty) {
                                          controller.text = "";
                                        }
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          onChanged: (val) =>
                                              _searchQuery.value = val,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "Search by Vehicle No...",
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                            suffixIcon:
                                                _searchQuery.value.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      controller.clear();
                                                      _searchQuery.value = "";
                                                    },
                                                  )
                                                : null,
                                            filled: true,
                                            fillColor: isDark
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.black.withOpacity(
                                                    0.05,
                                                  ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                        );
                                      },
                                  optionsViewBuilder:
                                      (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 8,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            child: Container(
                                              width: constraints.maxWidth - 32,
                                              constraints: const BoxConstraints(
                                                maxHeight: 250,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                ),
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: options.length,
                                                shrinkWrap: true,
                                                itemBuilder: (context, index) {
                                                  final option = options
                                                      .elementAt(index);
                                                  return ListTile(
                                                    title: Text(
                                                      option,
                                                      style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    onTap: () =>
                                                        onSelected(option),
                                                    dense: true,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // --- Filtered Card List ---
                            Expanded(
                              child: ValueListenableBuilder<String>(
                                valueListenable: _searchQuery,
                                builder: (context, query, _) {
                                  final filteredData = status.data.where((
                                    sale,
                                  ) {
                                    if (query.isEmpty) return true;
                                    final vehicleNo =
                                        sale['Vehical_No']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return vehicleNo.contains(
                                      query.toLowerCase(),
                                    );
                                  }).toList();

                                  if (filteredData.isEmpty &&
                                      !status.isLoading) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.black26,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No results for \"$query\"",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: filteredData.length,
                                    itemBuilder: (context, index) =>
                                        _buildMobileCard(
                                          filteredData[index],
                                          index,
                                          context,
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status.isLoading)
                        ProgressOverlay(
                          progress: status.progress,
                          currentCount: status.data.length,
                        ),
                      Positioned(
                        bottom: 20,
                        right: 20,
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
                }

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1000,
                      child: Stack(
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
                            ProgressOverlay(
                              progress: status.progress,
                              currentCount: status.data.length,
                            ),
                          Positioned(
                            bottom: 40,
                            right: 40,
                            child: FloatingActionButton(
                              backgroundColor: isDark
                                  ? StyleConstants.darkAccent
                                  : StyleConstants.lightAccent,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              shape: const CircleBorder(),
                              elevation: 4,
                              onPressed: () => fetchPointSales(),
                              child: const Icon(Icons.refresh_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );

            final rightPanel = Padding(
              padding: EdgeInsets.fromLTRB(
                isNarrow ? 24 : 0,
                isNarrow ? 0 : 24,
                24,
                24,
              ),
              child: SizedBox(
                width: isNarrow ? double.infinity : 380,
                height: isNarrow ? 500 : double.infinity,
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
            );

            if (isNarrow) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 600, child: mainContent),
                    rightPanel,
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(child: mainContent),
                rightPanel,
              ],
            );
          },
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

  Widget _buildMobileCard(dynamic sale, int index, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fuelTypeName = sale['FuelTypeName'] ?? 'Unknown';
    final saleTypeName = sale['Sale_Type_name'] ?? 'Unknown';
    final date = DateFormat(
      'dd-MM-yy HH:mm',
    ).format(DateTime.parse(sale['S_Date']));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VOUCHER: ${sale['VocNo']}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "VEHICLE: ${sale['Vehical_No'] ?? '-'}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getSaleTypeColor(saleTypeName).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getSaleTypeColor(saleTypeName).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    saleTypeName,
                    style: TextStyle(
                      color: getSaleTypeColor(saleTypeName),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FUEL TYPE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: getFuelColor(fuelTypeName),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fuelTypeName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "LITER",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${sale['SALELITER']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "AMOUNT",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${formatter.format(sale['TotalPrice'])} MMK",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child:
                  (saleTypeName == 'Cash Sale' ||
                      saleTypeName == 'ePayment' ||
                      saleTypeName == 'Credit Sale')
                  ? CheckAlreadyCollected(sale: sale)
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block_flipped,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Not Eligible",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          );
        }
        if (snapshot.data == true) {
          return const Icon(Icons.check_circle, color: Colors.green, size: 24);
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 750;

        if (_useCameraScanner || isMobile) {
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

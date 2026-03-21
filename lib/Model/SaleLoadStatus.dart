class SalesLoadStatus {
  final List<dynamic> data;
  final double progress;
  final bool isLoading;
  final List<Map<String, dynamic>>? stationProgress;

  SalesLoadStatus({
    required this.data,
    required this.progress,
    required this.isLoading,
    this.stationProgress,
  });
}

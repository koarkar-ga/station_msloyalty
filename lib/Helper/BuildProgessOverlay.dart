import 'dart:ui';

import 'package:flutter/material.dart';

class ProgressOverlay extends StatefulWidget {
  final double progress;
  final int currentCount;
  final List<Map<String, dynamic>>? stationProgress;

  const ProgressOverlay({
    super.key,
    required this.progress,
    required this.currentCount,
    this.stationProgress,
  });

  @override
  State<ProgressOverlay> createState() => _ProgressOverlayState();
}

class _ProgressOverlayState extends State<ProgressOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),

          Center(
            child: Container(
              width: 400,
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ဒေတာများ ရယူနေပါသည်",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Linear Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (widget.stationProgress != null &&
                      widget.stationProgress!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 10),
                    Flexible(
                      child: Scrollbar(
                        controller: _scrollController, // controller ပေးထားရမည်
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController, // controller ပေးထားရမည်
                          itemCount: widget.stationProgress!.length,
                          itemBuilder: (context, index) {
                            final station = widget.stationProgress![index];
                            final bool isDone = station['status'] == 'done';
                            final bool isCurrent = station['status'] == 'loading';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle
                                        : (isCurrent
                                            ? Icons.sync
                                            : Icons.circle_outlined),
                                    color: isDone
                                        ? Colors.green
                                        : (isCurrent ? Colors.blue : Colors.grey),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      station['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDone
                                            ? Colors.green
                                            : (isCurrent
                                                ? Colors.blue
                                                : Colors.black54),
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    "ရရှိပြီးသော စောင်ရေ - ${widget.currentCount}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

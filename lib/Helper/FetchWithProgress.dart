import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';

Future<void> fetchWithProgress(
  String apiUrl,
  List<dynamic> allData,
  StreamController<SalesLoadStatus> controller, {
  List<Map<String, dynamic>>? stationProgress,
  bool stayLoading = false,
  Map<String, String>? headers,
}) async {
  HttpClient client = HttpClient();
  
  try {
    HttpClientRequest request = await client.getUrl(Uri.parse(apiUrl));

    // Add headers (either passed or from AppConfig)
    final effectiveHeaders = headers ?? AppConfig.headers;
    effectiveHeaders.forEach((key, value) {
      request.headers.set(key, value);
    });

    HttpClientResponse response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Failed to load data: ${response.statusCode}');
    }

    String? countHeader = response.headers.value('x-total-count');
    int totalRecords = countHeader != null ? int.parse(countHeader) : 0;

    int currentRecordCount = 0;
    
    // Initial emit
    if (controller.hasListener) {
      controller.add(
        SalesLoadStatus(
          data: List.from(allData),
          progress: 0.0,
          isLoading: true,
          stationProgress: stationProgress,
        ),
      );
    }
    
    // Clear old data for this specific fetch
    // allData.clear(); // We handle clearing in the caller for "ALL" station loop

    await for (String line in response.transform(utf8.decoder).transform(const LineSplitter())) {
      String cleanLine = line.trim();
      if (cleanLine.isNotEmpty && cleanLine != "[" && cleanLine != "]") {
        if (cleanLine.endsWith(",")) {
          cleanLine = cleanLine.substring(0, cleanLine.length - 1);
        }

        try {
          var row = jsonDecode(cleanLine);
          allData.add(row);
          currentRecordCount++;

          if (totalRecords > 0) {
            double progress = currentRecordCount / totalRecords;

            // Emit every 10 records to avoid hammering the stream
            if (currentRecordCount % 10 == 0 || currentRecordCount == totalRecords) {
              if (controller.hasListener) {
                controller.add(
                  SalesLoadStatus(
                    data: List.from(allData),
                    progress: progress,
                    isLoading: true,
                    stationProgress: stationProgress,
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Row Error: $e");
        }
      }
    }

    // Final emit
    if (controller.hasListener) {
      controller.add(
        SalesLoadStatus(
          data: List.from(allData),
          progress: 1.0,
          isLoading: stayLoading,
          stationProgress: stayLoading ? stationProgress : null,
        ),
      );
    }
  } catch (e) {
    debugPrint("Fetch error: $e");
    rethrow;
  } finally {
    client.close();
  }
}

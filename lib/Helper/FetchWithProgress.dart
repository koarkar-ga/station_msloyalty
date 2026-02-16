//API Control with Loading Percentage
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:station_msloyalty/Constants/constant.dart';
import 'package:station_msloyalty/Model/SaleLoadStatus.dart';

Future<void> fetchWithProgress(String apiUrl, List<dynamic> allData) async {
  HttpClient client = HttpClient();
  HttpClientRequest request = await client.getUrl(Uri.parse(apiUrl));
  HttpClientResponse response = await request.close();

  String? countHeader = response.headers.value('x-total-count');
  int totalRecords = countHeader != null ? int.parse(countHeader) : 0;

  int currentRecordCount = 0;
  salesStreamController.add(
    SalesLoadStatus(data: List.from(allData), progress: 0.0, isLoading: true),
  );
  allData.clear();

  response
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        (String line) {
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

                // ဒေတာ ၁၀ ခုရောက်တိုင်း Stream ထဲကို အချက်အလက်အသစ် ပို့မယ်
                // ဒီနေရာမှာ setState ခေါ်စရာ မလိုတော့ဘူး!
                if (currentRecordCount % 10 == 0 || currentRecordCount == totalRecords) {
                  print(allData.length);
                  salesStreamController.add(
                    SalesLoadStatus(data: List.from(allData), progress: progress, isLoading: true),
                  );
                }
              }
            } catch (e) {
              print("Row Error: $e");
            }
          }
        },
        onDone: () {
          // အားလုံးပြီးသွားရင် Loading False လုပ်ပြီး Final Data ကို ပို့မယ်

          salesStreamController.add(
            SalesLoadStatus(data: List.from(allData), progress: 1.0, isLoading: false),
          );
        },
      );
}

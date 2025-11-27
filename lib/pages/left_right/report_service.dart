import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportService {
  Future<String?> saveJsonToFile(Map<String, dynamic> jsonData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String timestamp = jsonData['session_id'] ?? 'report';
      String filename = 'stability_report_$timestamp.json';
      final file = File('${directory.path}/$filename');
      String jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
      await file.writeAsString(jsonString);
      print('Report saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  Future<void> shareReport(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: 'Stability Report',
        text: 'Sensor stability test report from Goniometer App',
      );
    } catch (e) {
      print('Error sharing file: $e');
      // You could show a dialog here if you wanted
    }
  }
}
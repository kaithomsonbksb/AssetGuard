import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:assetguard/models/inspection_item.dart';

/// handles HTTP calls to the Flask sync server (server.py)
/// change the IP in _baseUrl when testing on a real Android device
class ApiService {
  ApiService._privateConstructor();

  static final ApiService instance = ApiService._privateConstructor();

  /// use localhost for desktop, 10.0.2.2 for the Android emulator
  static String get _baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 maps to the host machine's localhost from inside the emulator
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  /// upload a single inspection record to the server
  /// returns true if the server accepted it (HTTP 200), false otherwise
  Future<bool> uploadInspection(InspectionItem inspection) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/inspections/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'inspection_id': inspection.inspectionId,
              'job_id': inspection.jobId,
              'notes': inspection.notes,
              'result': inspection.result,
              'updated_at': inspection.updatedAt.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          '[ApiService] ${inspection.inspectionId}: HTTP ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      // network error or timeout — treat as failed
      debugPrint('[ApiService] upload failed for ${inspection.inspectionId}: $e');
      return false;
    }
  }
}

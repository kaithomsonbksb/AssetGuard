import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/models/inspection_item.dart';

/// SyncManager handles synchronization of pending inspection items to remote server
class SyncManager {
  SyncManager._privateConstructor();

  static final SyncManager instance = SyncManager._privateConstructor();

  // API endpoint configuration - change to your server URL
  static const String _apiBaseUrl = 'http://192.168.1.91:5000';
  static const String _syncEndpoint = '$_apiBaseUrl/inspections/sync';
  static const String _syncBatchEndpoint = '$_apiBaseUrl/inspections/sync-batch';

  /// get all pending inspection items that need to be synced
  Future<List<InspectionItem>> getPendingInspections() async {
    try {
      final db = DatabaseHelper.instance;
      final allInspections = await db.database;

      // query for pending inspections
      final pendingMaps = await allInspections.query(
        'inspection_items',
        where: 'sync_state = ?',
        whereArgs: ['pending'],
      );

      return pendingMaps
          .map((map) => InspectionItem.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending inspections: $e');
      return [];
    }
  }

  /// sync pending inspection items
  Future<bool> syncPendingInspections() async {
    try {
      final pendingInspections = await getPendingInspections();

      if (pendingInspections.isEmpty) {
        debugPrint('No pending inspections to sync');
        return true;
      }

      debugPrint('Syncing ${pendingInspections.length} pending inspections...');

      bool allSynced = true;

      for (final inspection in pendingInspections) {
        final success = await _syncInspectionItem(inspection);
        if (!success) {
          allSynced = false;
        }
      }

      return allSynced;
    } catch (e) {
      debugPrint('Error during sync: $e');
      return false;
    }
  }

  /// sync a single inspection item
  /// attempts to upload it to the remote server
  /// updates local sync_state to 'synced' or 'failed'
  Future<bool> _syncInspectionItem(InspectionItem inspection) async {
    try {
      debugPrint('Syncing inspection ${inspection.inspectionId}...');

      // simulate API call
      final uploadSuccess = await _uploadInspectionToServer(inspection);

      if (uploadSuccess) {
        // update sync state to 'synced'
        final updatedInspection = inspection.copyWith(syncState: 'synced');
        await DatabaseHelper.instance
            .updateInspectionItem(updatedInspection);

        debugPrint('Successfully synced inspection ${inspection.inspectionId}');
        return true;
      } else {
        // update sync state to 'failed'
        final updatedInspection = inspection.copyWith(syncState: 'failed');
        await DatabaseHelper.instance
            .updateInspectionItem(updatedInspection);

        debugPrint('Failed to sync inspection ${inspection.inspectionId}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing inspection ${inspection.inspectionId}: $e');

      // update sync state to 'failed' due to exception
      try {
        final failedInspection = inspection.copyWith(syncState: 'failed');
        await DatabaseHelper.instance
            .updateInspectionItem(failedInspection);
      } catch (updateError) {
        debugPrint('Error updating inspection state: $updateError');
      }

      return false;
    }
  }

  /// simulates uploading inspection item to remote server
  /// for now, returns true to simulate successful upload
  Future<bool> _uploadInspectionToServer(InspectionItem inspection) async {
    try {
      debugPrint('Uploading inspection ${inspection.inspectionId} to server...');

      final response = await http.post(
        Uri.parse(_syncEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inspection_id': inspection.inspectionId,
          'job_id': inspection.jobId,
          'notes': inspection.notes,
          'result': inspection.result,
          'updated_at': inspection.updatedAt.toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      debugPrint(
          'Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Successfully uploaded inspection ${inspection.inspectionId}');
        return true;
      } else {
        debugPrint('Upload failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  /// retry syncing failed inspection items
  Future<bool> retrySyncFailedInspections() async {
    try {
      final db = DatabaseHelper.instance;
      final allInspections = await db.database;

      // Query for failed inspections
      final failedMaps = await allInspections.query(
        'inspection_items',
        where: 'sync_state = ?',
        whereArgs: ['failed'],
      );

      if (failedMaps.isEmpty) {
        debugPrint('No failed inspections to retry');
        return true;
      }

      debugPrint('Retrying ${failedMaps.length} failed inspections...');

      bool allSynced = true;

      for (final map in failedMaps) {
        final inspection = InspectionItem.fromMap(map);
        final success = await _syncInspectionItem(inspection);
        if (!success) {
          allSynced = false;
        }
      }

      return allSynced;
    } catch (e) {
      debugPrint('Error retrying failed inspections: $e');
      return false;
    }
  }

  /// Batch sync multiple inspections at once (more efficient)
  Future<bool> syncPendingInspectionsBatch() async {
    try {
      final pendingInspections = await getPendingInspections();

      if (pendingInspections.isEmpty) {
        debugPrint('No pending inspections to sync');
        return true;
      }

      debugPrint(
          'Batch syncing ${pendingInspections.length} pending inspections...');

      final response = await http.post(
        Uri.parse(_syncBatchEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inspections': pendingInspections.map((inspection) {
            return {
              'inspection_id': inspection.inspectionId,
              'job_id': inspection.jobId,
              'notes': inspection.notes,
              'result': inspection.result,
              'updated_at': inspection.updatedAt.toIso8601String(),
            };
          }).toList(),
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Batch sync timeout after 60 seconds');
        },
      );

      debugPrint('Batch sync response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final results = responseData['results'] ?? {};
        final successful =
            (results['successful'] as List?)?.length ?? 0;
        final failed = (results['failed'] as List?)?.length ?? 0;

        debugPrint(
            'Batch sync completed: $successful successful, $failed failed');

        // Update sync state for all synced inspections
        for (final inspection in pendingInspections) {
          try {
            final updatedInspection =
                inspection.copyWith(syncState: 'synced');
            await DatabaseHelper.instance
                .updateInspectionItem(updatedInspection);
          } catch (e) {
            debugPrint('Error updating inspection: $e');
          }
        }

        return failed == 0;
      } else {
        debugPrint('Batch sync failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during batch sync: $e');
      return false;
    }
  }

  /// Check server health
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/health'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Health check timeout');
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
}

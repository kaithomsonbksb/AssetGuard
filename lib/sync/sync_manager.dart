import 'package:flutter/foundation.dart';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/models/inspection_item.dart';

/// SyncManager handles synchronization of pending inspection items to remote server
class SyncManager {
  SyncManager._privateConstructor();

  static final SyncManager instance = SyncManager._privateConstructor();

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
      // TODO: Replace with actual HTTP POST request
      // Example:
      // final response = await http.post(
      //   Uri.parse('$_apiEndpoint/${inspection.inspectionId}'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(inspection.toMap()),
      // );
      // return response.statusCode == 200;

      await Future.delayed(const Duration(milliseconds: 500));

      final isSuccess = DateTime.now().millisecond % 10 != 0;

      return isSuccess;
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
}

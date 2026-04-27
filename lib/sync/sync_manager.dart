import 'package:flutter/foundation.dart';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/services/api_service.dart';

/// holds the result of a sync run so the UI can show a sensible message
class SyncResult {
  final int synced;
  final int failed;
  final int pulled;

  const SyncResult({
    required this.synced,
    required this.failed,
    this.pulled = 0,
  });
}

/// handles the offline-first sync workflow:
/// push pending/failed inspections up to the server first,
/// then pull all server records down so every device stays in sync
class SyncManager {
  SyncManager._privateConstructor();

  static final SyncManager instance = SyncManager._privateConstructor();

  /// push any pending/failed records, then pull everything from the server
  /// returns a SyncResult with counts for uploaded, pulled, and failed
  Future<SyncResult> syncAll() async {
    int synced = 0;
    int failed = 0;
    int pulled = 0;

    try {
      // --- push phase ---
      // get everything that still needs to be sent to the server
      final pending =
          await DatabaseHelper.instance.getPendingAndFailedInspections();

      debugPrint('[SyncManager] pushing ${pending.length} inspection(s)...');

      for (final inspection in pending) {
        final success = await ApiService.instance.uploadInspection(inspection);

        // update the local record to match what happened
        final newState = success ? 'synced' : 'failed';
        await DatabaseHelper.instance
            .updateInspectionSyncState(inspection.inspectionId, newState);

        if (success) {
          synced++;
          debugPrint('[SyncManager] uploaded ${inspection.inspectionId}');
        } else {
          failed++;
          debugPrint('[SyncManager] upload failed ${inspection.inspectionId}');
        }
      }

      // --- pull phase ---
      // download all records from the server and upsert them locally
      // server copy wins — this keeps all devices in sync
      final downloaded = await ApiService.instance.downloadInspections();

      for (final item in downloaded) {
        // insertInspectionItem uses ConflictAlgorithm.replace so this is an upsert
        await DatabaseHelper.instance.insertInspectionItem(item);
        pulled++;
      }

      debugPrint('[SyncManager] pulled $pulled inspection(s) from server');
    } catch (e) {
      debugPrint('[SyncManager] unexpected error: $e');
    }

    return SyncResult(synced: synced, failed: failed, pulled: pulled);
  }
}

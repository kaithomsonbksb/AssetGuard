import 'package:flutter/foundation.dart';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/services/api_service.dart';

/// holds the result of a sync run so the UI can show a sensible message
class SyncResult {
  final int synced;
  final int failed;

  const SyncResult({required this.synced, required this.failed});
}

/// handles the offline-first sync workflow:
/// fetches pending/failed inspections, uploads each to the server,
/// then updates the local sync_state based on whether it worked
class SyncManager {
  SyncManager._privateConstructor();

  static final SyncManager instance = SyncManager._privateConstructor();

  /// sync all pending and previously-failed inspections
  /// returns a SyncResult with counts of how many succeeded and failed
  Future<SyncResult> syncAll() async {
    int synced = 0;
    int failed = 0;

    try {
      // get everything that still needs to be sent to the server
      final inspections =
          await DatabaseHelper.instance.getPendingAndFailedInspections();

      if (inspections.isEmpty) {
        debugPrint('[SyncManager] nothing to sync');
        return const SyncResult(synced: 0, failed: 0);
      }

      debugPrint('[SyncManager] syncing ${inspections.length} inspection(s)...');

      for (final inspection in inspections) {
        final success = await ApiService.instance.uploadInspection(inspection);

        // update the local record to match what happened
        final newState = success ? 'synced' : 'failed';
        await DatabaseHelper.instance
            .updateInspectionSyncState(inspection.inspectionId, newState);

        if (success) {
          synced++;
          debugPrint('[SyncManager] synced ${inspection.inspectionId}');
        } else {
          failed++;
          debugPrint('[SyncManager] failed ${inspection.inspectionId}');
        }
      }
    } catch (e) {
      debugPrint('[SyncManager] unexpected error: $e');
    }

    return SyncResult(synced: synced, failed: failed);
  }
}

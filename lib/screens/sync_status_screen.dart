import 'package:flutter/material.dart';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/models/inspection_item.dart';
import 'package:assetguard/sync/sync_manager.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  late Future<List<InspectionItem>> _inspectionsFuture;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _inspectionsFuture = _loadInspections();
  }

  /// load all inspection records from the database
  Future<List<InspectionItem>> _loadInspections() {
    return DatabaseHelper.instance.getAllInspectionItems();
  }

  /// run a sync and refresh the list when it finishes
  Future<void> _runSync() async {
    setState(() => _isSyncing = true);

    final result = await SyncManager.instance.syncAll();

    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _inspectionsFuture = _loadInspections();
    });

    // build a message from whichever counts are non-zero
    final parts = <String>[];
    if (result.synced > 0) parts.add('${result.synced} uploaded');
    if (result.pulled > 0) parts.add('${result.pulled} pulled');
    if (result.failed > 0) parts.add('${result.failed} failed');
    final message = parts.isEmpty ? 'nothing to sync' : parts.join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// pick a colour based on sync state
  Color _stateColor(String state) {
    switch (state) {
      case 'synced':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  /// pick an icon based on sync state
  IconData _stateIcon(String state) {
    switch (state) {
      case 'synced':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          // show spinner while syncing, otherwise show the sync button
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync pending inspections',
              onPressed: _runSync,
            ),
        ],
      ),
      body: FutureBuilder<List<InspectionItem>>(
        future: _inspectionsFuture,
        builder: (context, snapshot) {
          // show loading spinner while fetching
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('No inspections recorded yet'),
            );
          }

          // count each state for the summary row
          final synced = items.where((i) => i.syncState == 'synced').length;
          final pending = items.where((i) => i.syncState == 'pending').length;
          final failed = items.where((i) => i.syncState == 'failed').length;

          return Column(
            children: [
              // summary cards at the top
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _SummaryCard(
                        label: 'Synced', count: synced, color: Colors.green),
                    const SizedBox(width: 8),
                    _SummaryCard(
                        label: 'Pending', count: pending, color: Colors.amber),
                    const SizedBox(width: 8),
                    _SummaryCard(
                        label: 'Failed', count: failed, color: Colors.red),
                  ],
                ),
              ),
              // list of all inspection records
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final color = _stateColor(item.syncState);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Icon(_stateIcon(item.syncState), color: color),
                        title: Text('${item.jobId}  •  ${item.result}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // truncate long notes so the list stays readable
                            Text(
                              item.notes.length > 60
                                  ? '${item.notes.substring(0, 60)}...'
                                  : item.notes,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              item.updatedAt.toString().split('.').first,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(item.syncState),
                          backgroundColor: color.withValues(alpha: 0.15),
                          labelStyle:
                              TextStyle(color: color, fontSize: 12),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// small summary card showing a count and label for one sync state
class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}

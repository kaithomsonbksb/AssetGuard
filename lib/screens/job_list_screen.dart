import 'package:flutter/material.dart';
import 'package:assetguard/database/database_helper.dart';
import 'package:assetguard/models/job.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late Future<List<Job>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = _loadJobs();
  }

  /// load jobs from database, show sample jobs on first load
  Future<List<Job>> _loadJobs() async {
    await DatabaseHelper.instance.seedSampleJobs();
    return DatabaseHelper.instance.getAllJobs();
  }

  /// refresh the jobs list
  Future<void> _refreshJobs() async {
    setState(() {
      _jobsFuture = _loadJobs();
    });
  }

  /// get the sync status of inspections for a job
  /// returns "Pending sync", "Synced", "Failed", or "No inspections"
  Future<String> _getInspectionSyncStatus(String jobId) async {
    final inspections = await DatabaseHelper.instance.getInspectionItemsByJobId(jobId);

    if (inspections.isEmpty) {
      return 'No inspections';
    }

    // check for any failed syncs
    if (inspections.any((item) => item.syncState == 'failed')) {
      return 'Failed';
    }

    // check if all are synced
    if (inspections.every((item) => item.syncState == 'synced')) {
      return 'Synced';
    }

    // otherwise, at least one is pending
    return 'Pending sync';
  }

  /// get the color for the sync status chip
  Color _getSyncStatusColor(String status) {
    switch (status) {
      case 'Synced':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      case 'Pending sync':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Jobs'),
      ),
      body: FutureBuilder<List<Job>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          // show loading spinner while fetching jobs
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CenteFutureBuilder<String>(
                      future: _getInspectionSyncStatus(job.jobId),
                      builder: (context, syncSnapshot) {
                        final syncStatus = syncSnapshot.data ?? 'No inspections';
                        final color = _getSyncStatusColor(syncStatus);

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // status
                            Chip(
                              label: Text(job.status),
                              backgroundColor: Colors.blue.shade100,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(syncStatus),
                              backgroundColor: color.withOpacity(0.2),
                              labelStyle: TextStyle(color: color),
                            ),
                          ],
                        );
                      }

          // show error message if something went wrong
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading jobs: ${snapshot.error}'),
            );
          }

          final jobs = snapshot.data ?? [];

          // show empty state if no jobs found
          if (jobs.isEmpty) {
            return const Center(
              child: Text('No inspection jobs found'),
            );
          }

          // display jobs in a list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(job.siteName),
                    subtitle: Text(
                      '${job.assignedEngineer} • Due: ${job.dueDate.toString().split(' ').first}',
                    ),
                    trailing: Chip(
                      label: Text(job.status),
                    ),
                    onTap: () {
                      // navigate to inspection detail screen with selected job
                      Navigator.of(context).pushNamed(
                        '/inspection',
                        arguments: job,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';

class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Jobs'),
      ),
      body: const Center(
        child: Text('Job list will appear here'),
      ),
    );
  }
}
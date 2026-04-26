import 'package:flutter/material.dart';
import 'package:assetguard/models/job.dart';

/// InspectionDetailScreen displays details for a selected job
/// and allows the user to enter inspection results and notes
class InspectionDetailScreen extends StatefulWidget {
  final Job job;

  const InspectionDetailScreen({
    super.key,
    required this.job,
  });

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  //  key for validation
  final _formKey = GlobalKey<FormState>();

  // controller notes field
  late TextEditingController _notesController;

  // dropdown value for inspection result
  String _selectedResult = 'Pass';

  // list possible inspection results
  final List<String> _resultOptions = ['Pass', 'Fail', 'Requires attention'];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// handler for save button press
  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save inspection data to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // back to job list
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // job information section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      // site name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Site: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(widget.job.siteName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // assigned engineer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Engineer: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(widget.job.assignedEngineer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // due date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              widget.job.dueDate.toString().split(' ').first,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Chip(
                              label: Text(widget.job.status),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // inspection result dropdown
                Text(
                  'Inspection Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedResult,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: _resultOptions.map((String result) {
                      return DropdownMenuItem<String>(
                        value: result,
                        child: Text(result),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedResult = newValue ?? 'Pass';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // notes text field
                Text(
                  'Inspection Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter your inspection findings and observations',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter inspection notes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Inspection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

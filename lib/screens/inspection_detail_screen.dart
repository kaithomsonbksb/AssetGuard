import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assetguard/models/job.dart';
import 'package:assetguard/models/inspection_item.dart';
import 'package:assetguard/models/attachment.dart';
import 'package:assetguard/database/database_helper.dart';

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

  // photos selected by the user before saving
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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

  /// open the image picker and add any chosen photos to the list
  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  /// handle save button press - saves inspection data to local database
  void _handleSave() async {
    // validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an inspection result'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // create new inspection item - unique ID
      final inspectionItem = InspectionItem(
        inspectionId: const Uuid().v4(), // Generate unique ID
        jobId: widget.job.jobId,
        notes: _notesController.text.trim(),
        result: _selectedResult,
        updatedAt: DateTime.now(),
        syncState: 'pending', // Mark as pending sync
      );

      // save inspection to local db
      await DatabaseHelper.instance.insertInspectionItem(inspectionItem);

      // save each selected photo as an attachment linked to this inspection
      for (final image in _selectedImages) {
        final attachment = Attachment(
          attachmentId: const Uuid().v4(),
          inspectionId: inspectionItem.inspectionId,
          filePath: image.path,
          fileType: 'image',
          syncState: 'pending',
        );
        await DatabaseHelper.instance.insertAttachment(attachment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // back to job list
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // show error message if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    //  minimum length <10 char
                    if (value.trim().length < 10) {
                      return 'Notes must be at least 10 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // photo attachments section
                Text(
                  'Attachments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                // thumbnails of selected photos
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // tap X to remove a photo before saving
                            Positioned(
                              top: 0,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(index)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add photos'),
                  onPressed: _pickImages,
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

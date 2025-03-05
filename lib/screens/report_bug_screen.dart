import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/toast_utils.dart';
import '../widgets/bottom_nav_bar.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({Key? key}) : super(key: key);

  @override
  _ReportBugScreenState createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedIssueType = 'App Crashing';
  final TextEditingController _affectedFilesController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'App Crashing',
    'Audio Not Playing',
    'Audio Download Not Working',
    'Ebook Not Opening',
    'Incorrect File Title',
    'Search Not Working',
    'Video Playback Issues',
    'Bible Text Not Loading',
    'Devotional Content Missing',
    'Navigation Problems',
    'Dark Mode Issues',
    'Slow Performance',
    'Notification Issues',
    'Login Problems',
    'Other'
  ];

  @override
  void dispose() {
    _affectedFilesController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await FirebaseFirestore.instance.collection('bug_reports').add({
          'issueType': _selectedIssueType,
          'affectedFiles': _affectedFilesController.text,
          'comments': _commentsController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'new',
        });

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          
          // Reset form
          _selectedIssueType = 'App Crashing';
          _affectedFilesController.clear();
          _commentsController.clear();
          
          ToastUtils.showToast('Bug report submitted successfully');
          
          // Go back to previous screen
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
          ToastUtils.showToast('Error submitting bug report: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Bug'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help us improve the app by reporting any issues you encounter',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Issue Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _issueTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedIssueType = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an issue type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              Text(
                'Affected Files/Content (if applicable)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _affectedFilesController,
                decoration: InputDecoration(
                  hintText: 'E.g., Sermon title, Bible version, Video name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Additional Comments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(
                  hintText: 'Please describe the issue in detail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide some details about the issue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBugReport,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit Bug Report'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 5),
    );
  }
}

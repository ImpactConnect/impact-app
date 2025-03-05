import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/mock_data.dart';
import '../../utils/toast_utils.dart';

class PopulateDataScreen extends StatefulWidget {
  const PopulateDataScreen({Key? key}) : super(key: key);

  @override
  State<PopulateDataScreen> createState() => _PopulateDataScreenState();
}

class _PopulateDataScreenState extends State<PopulateDataScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _populateMockLiveStreams() async {
    try {
      final collection = _firestore.collection('live_streams');

      // Current live stream
      await collection.add({
        'title': 'Sunday Morning Service',
        'url': 'https://www.youtube.com/embed/live_stream?channel=CHANNEL_ID',
        'platform': 'youtube',
        'isLive': true,
        'startTime': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(minutes: 30))),
        'endTime': null,
      });

      // Upcoming streams
      final upcomingTimes = [
        DateTime.now().add(const Duration(days: 3)),
        DateTime.now().add(const Duration(days: 7)),
      ];

      for (var time in upcomingTimes) {
        await collection.add({
          'title': 'Upcoming Sunday Service',
          'url': 'https://www.youtube.com/embed/live_stream?channel=CHANNEL_ID',
          'platform': 'youtube',
          'isLive': false,
          'startTime': Timestamp.fromDate(time),
          'endTime': Timestamp.fromDate(time.add(const Duration(hours: 2))),
        });
      }

      // Past streams
      final pastTimes = [
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now().subtract(const Duration(days: 14)),
      ];

      for (var time in pastTimes) {
        await collection.add({
          'title': 'Past Sunday Service',
          'url': 'https://www.youtube.com/embed/watch?v=PAST_VIDEO_ID',
          'platform': 'youtube',
          'isLive': false,
          'startTime': Timestamp.fromDate(time),
          'endTime': Timestamp.fromDate(time.add(const Duration(hours: 2))),
        });
      }

      if (!mounted) return;
      ToastUtils.showSuccessToast('Mock live streams added successfully');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showErrorToast('Error adding mock live streams: $e');
    }
  }

  Widget _buildButton({
    required String title,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Populate Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildButton(
            title: 'Add Mock Live Streams',
            onPressed: _populateMockLiveStreams,
            icon: Icons.live_tv,
          ),
          const SizedBox(height: 16),
          _buildButton(
            title: 'Populate Mock Data',
            onPressed: () async {
              try {
                await MockData.populateFirestore();
                if (!mounted) return;
                ToastUtils.showSuccessToast(
                    'Mock data populated successfully!');
              } catch (e) {
                if (!mounted) return;
                ToastUtils.showErrorToast('Error populating data: $e');
              }
            },
            icon: Icons.data_array,
          ),
          const SizedBox(height: 16),
          const Text(
            'This will add sample data to your Firebase collections:\n'
            '- 10 Sermons\n'
            '- 7 Categories\n'
            '- 7 Preachers\n'
            '- 15 Tags\n'
            '- 5 Live Streams',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

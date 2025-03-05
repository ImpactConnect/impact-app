import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({
    Key? key,
    required this.eventId,
    required this.title,
  }) : super(key: key);
  final String eventId;
  final String title;

  Future<DocumentSnapshot> _loadEventDetails() async {
    debugPrint('Loading event details for ID: $eventId');
    try {
      final docRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);
      debugPrint('Firestore reference: ${docRef.path}');
      final doc = await docRef.get();
      debugPrint('Document exists: ${doc.exists}');
      if (doc.exists) {
        debugPrint('Document data: ${doc.data()}');
      }
      return doc;
    } catch (e, stackTrace) {
      debugPrint('Error loading event details: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _loadEventDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error loading event: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading event details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            debugPrint('Event not found with ID: $eventId');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Event not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final eventData = snapshot.data!.data() as Map<String, dynamic>;
          debugPrint('Event data loaded: $eventData');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eventData['imageUrl'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      eventData['imageUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.church,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                eventData['title'] ?? 'Church Event',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  eventData['title'] ?? 'Untitled Event',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (eventData['startDate'] != null) ...[
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateFormat('MMMM d, yyyy').format(
                      (eventData['startDate'] as Timestamp).toDate(),
                    ),
                  ),
                ],
                if (eventData['programmeTime'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    eventData['programmeTime'],
                  ),
                ],
                if (eventData['venue'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    eventData['venue'],
                  ),
                ],
                if (eventData['description'] != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventData['description'],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

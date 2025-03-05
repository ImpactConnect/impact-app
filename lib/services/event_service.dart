import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../utils/toast_utils.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      print('Fetching upcoming events after: ${now.toIso8601String()}');

      try {
        // Try the optimized query first (requires index)
        print('Attempting optimized query with index...');
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('startDate', isGreaterThanOrEqualTo: now)
            .where('isUpcoming', isEqualTo: true)
            .orderBy('startDate')
            .get();

        final events =
            querySnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        print('Found ${events.length} events with optimized query');
        return events;
      } catch (e) {
        print('Optimized query error: $e');
        if (e is FirebaseException && e.code == 'permission-denied') {
          ToastUtils.showToast(
              'Please update Firestore rules to allow read access');
          return [];
        }
        if (e.toString().contains('The query requires an index')) {
          // Fallback query while waiting for index
          print('Using fallback query...');
          ToastUtils.showToast('Loading events...');

          final querySnapshot = await _firestore
              .collection(_collection)
              .orderBy('startDate')
              .get();

          final events = querySnapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .where(
                  (event) => event.startDate.isAfter(now) && event.isUpcoming)
              .toList();
          print('Found ${events.length} events with fallback query');
          return events;
        }
        rethrow;
      }
    } catch (e) {
      print('Error getting upcoming events: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        ToastUtils.showToast(
            'Please update Firestore rules to allow read access');
      }
      return [];
    }
  }

  // Search events by title
  Future<List<Event>> searchEvents(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching events: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        ToastUtils.showToast(
            'Please update Firestore rules to allow read access');
      }
      return [];
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(eventId).get();

      if (!docSnapshot.exists) return null;
      return Event.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error getting event: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        ToastUtils.showToast(
            'Please update Firestore rules to allow read access');
      }
      return null;
    }
  }

  // Add sample events for testing
  Future<void> addSampleEvents() async {
    try {
      print('Starting to add sample events...');

      // First, check if we can access Firestore
      try {
        final testDoc = await _firestore.collection(_collection).add({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await testDoc.delete();
        print('Successfully tested write access to Firestore');
      } catch (e) {
        print('Error writing to Firestore: $e');
        if (e is FirebaseException &&
            (e.code == 'permission-denied' ||
                e.code == 'failed-precondition')) {
          ToastUtils.showToast(
              'Please update Firestore rules to allow write access');
          return;
        }
        ToastUtils.showToast('Error connecting to database');
        return;
      }

      final batch = _firestore.batch();
      print('Created write batch');

      // Sample event 1
      final event1 = {
        'title': 'Sunday Service',
        'description':
            'Join us for our weekly Sunday service filled with worship and fellowship.',
        'imageUrl': 'https://example.com/sunday-service.jpg',
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 2, hours: 2))),
        'venue': 'Main Sanctuary',
        'programmeTime': '10:00 AM - 12:00 PM',
        'isUpcoming': true,
      };

      // Sample event 2
      final event2 = {
        'title': 'Youth Fellowship',
        'description':
            'Special youth gathering with games, worship, and Bible study.',
        'imageUrl': 'https://example.com/youth-fellowship.jpg',
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 5, hours: 3))),
        'venue': 'Youth Center',
        'programmeTime': '6:00 PM - 9:00 PM',
        'isUpcoming': true,
      };

      // Sample event 3
      final event3 = {
        'title': 'Prayer Meeting',
        'description':
            'Mid-week prayer meeting for spiritual growth and community support.',
        'imageUrl': 'https://example.com/prayer-meeting.jpg',
        'startDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7, hours: 1))),
        'venue': 'Prayer Room',
        'programmeTime': '7:00 PM - 8:00 PM',
        'isUpcoming': true,
      };

      print('Created sample event data');

      // Add events to batch
      try {
        batch.set(_firestore.collection(_collection).doc(), event1);
        batch.set(_firestore.collection(_collection).doc(), event2);
        batch.set(_firestore.collection(_collection).doc(), event3);
        print('Added events to batch');
      } catch (e) {
        print('Error adding events to batch: $e');
        ToastUtils.showToast('Error preparing events');
        return;
      }

      // Commit the batch
      try {
        await batch.commit();
        print('Successfully committed batch');
        ToastUtils.showToast('Sample events added successfully');
      } catch (e) {
        print('Error committing batch: $e');
        if (e is FirebaseException &&
            (e.code == 'permission-denied' ||
                e.code == 'failed-precondition')) {
          ToastUtils.showToast(
              'Please update Firestore rules to allow write access');
        } else {
          ToastUtils.showToast('Error saving events');
        }
        return;
      }
    } catch (e) {
      print('Unexpected error adding sample events: $e');
      ToastUtils.showToast('Failed to add sample events');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class MockDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateMockCarouselData() async {
    // Create carousel collections config
    await _firestore.collection('carousel_config').doc('collections').set({
      'paths': [
        'carousels/announcements',
        'carousels/events',
        'carousels/sermons',
      ]
    });

    // Announcements Carousel
    final announcements = [
      {
        'title': 'Welcome to Impact Connect',
        'description': 'Your digital gateway to our church community',
        'imageUrl':
            'https://images.unsplash.com/photo-1438032005730-c779502df39b',
        'isActive': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Sunday Service Times',
        'description': 'Join us every Sunday at 9:00 AM and 11:00 AM',
        'imageUrl':
            'https://images.unsplash.com/photo-1507692049790-de58290a4334',
        'linkUrl': '/schedule',
        'linkType': 'inApp',
        'isActive': true,
        'order': 2,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Download Our App',
        'description': 'Stay connected with our church community',
        'imageUrl':
            'https://images.unsplash.com/photo-1581287053822-fd7bf4f4bfec',
        'linkUrl': 'https://play.google.com/store',
        'linkType': 'external',
        'isActive': true,
        'order': 3,
        'createdAt': Timestamp.now(),
      },
    ];

    // Events Carousel
    final events = [
      {
        'title': 'Youth Conference 2024',
        'description': 'Join us for three days of worship and fellowship',
        'imageUrl':
            'https://images.unsplash.com/photo-1526653054275-5a4f37ea1c64',
        'linkUrl': '/events/youth-conference',
        'linkType': 'inApp',
        'isActive': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Easter Service',
        'description': 'Celebrate the resurrection with us',
        'imageUrl': 'https://images.unsplash.com/photo-1544427920-c49ccfb85579',
        'linkUrl': '/events/easter',
        'linkType': 'inApp',
        'isActive': true,
        'order': 2,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Community Outreach',
        'description': 'Serving our local community together',
        'imageUrl':
            'https://images.unsplash.com/photo-1593113598332-cd288d649433',
        'linkUrl': '/events/outreach',
        'linkType': 'inApp',
        'isActive': true,
        'order': 3,
        'createdAt': Timestamp.now(),
      },
    ];

    // Sermons Carousel
    final sermons = [
      {
        'title': 'Latest Sermon Series',
        'description': 'Walking in Faith: A Journey Through Hebrews',
        'imageUrl':
            'https://images.unsplash.com/photo-1490127252417-7c393f993ee4',
        'linkUrl': '/sermons/latest',
        'linkType': 'inApp',
        'isActive': true,
        'order': 1,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Watch Live',
        'description': 'Join our Sunday service online',
        'imageUrl':
            'https://images.unsplash.com/photo-1505236858219-8359eb29e329',
        'linkUrl': 'https://youtube.com/live',
        'linkType': 'external',
        'isActive': true,
        'order': 2,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Sermon Archive',
        'description': 'Access our complete sermon library',
        'imageUrl':
            'https://images.unsplash.com/photo-1585858229735-cd08d8cb0e63',
        'linkUrl': '/sermons',
        'linkType': 'inApp',
        'isActive': true,
        'order': 3,
        'createdAt': Timestamp.now(),
      },
    ];

    // Upload to Firebase
    final batch = _firestore.batch();

    // Add announcements
    for (var item in announcements) {
      final docRef =
          _firestore.collection('carousels/announcements/items').doc();
      batch.set(docRef, item);
    }

    // Add events
    for (var item in events) {
      final docRef = _firestore.collection('carousels/events/items').doc();
      batch.set(docRef, item);
    }

    // Add sermons
    for (var item in sermons) {
      final docRef = _firestore.collection('carousels/sermons/items').doc();
      batch.set(docRef, item);
    }

    // Commit all changes
    await batch.commit();
  }

  // Helper method to clear existing data
  Future<void> clearExistingCarouselData() async {
    final collections = [
      'carousels/announcements/items',
      'carousels/events/items',
      'carousels/sermons/items',
    ];

    for (var collectionPath in collections) {
      final snapshot = await _firestore.collection(collectionPath).get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Clear config
    await _firestore.collection('carousel_config').doc('collections').delete();
  }
}

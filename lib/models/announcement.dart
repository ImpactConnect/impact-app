import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  Announcement({
    required this.id,
    required this.message,
    required this.timePosted,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      message: data['message'] ?? '',
      timePosted: (data['timePosted'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String message;
  final DateTime timePosted;

  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'timePosted': Timestamp.fromDate(timePosted),
    };
  }
}

class MockAnnouncementData {
  static List<Map<String, dynamic>> getMockData() {
    final now = DateTime.now();
    return [
      {
        'message':
            'Join us this Sunday for our special Family and Friends service at 10 AM. There will be special presentations and refreshments after the service.',
        'timePosted':
            Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'message':
            'The Women\'s Fellowship monthly prayer meeting has been rescheduled to next Saturday at 4 PM.',
        'timePosted':
            Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
      },
      {
        'message':
            'Youth choir practice will be held this Friday at 6 PM. All youth members are encouraged to attend.',
        'timePosted':
            Timestamp.fromDate(now.subtract(const Duration(hours: 8))),
      },
      {
        'message':
            'Next week\'s Bible study will focus on the Book of Ruth. Please come prepared with your questions.',
        'timePosted':
            Timestamp.fromDate(now.subtract(const Duration(hours: 12))),
      },
      {
        'message':
            'The church cleaning exercise is scheduled for this Saturday at 7 AM. All volunteers are welcome.',
        'timePosted':
            Timestamp.fromDate(now.subtract(const Duration(hours: 24))),
      }
    ];
  }
}

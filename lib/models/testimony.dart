import 'package:cloud_firestore/cloud_firestore.dart';

class Testimony {
  Testimony({
    required this.id,
    required this.testifier,
    required this.testimony,
    required this.dateShared,
    this.imageUrl,
  });

  factory Testimony.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Testimony(
      id: doc.id,
      testifier: data['testifier'] ?? '',
      testimony: data['testimony'] ?? '',
      dateShared: (data['dateShared'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }
  final String id;
  final String testifier;
  final String testimony;
  final DateTime dateShared;
  final String? imageUrl;

  Map<String, dynamic> toFirestore() {
    return {
      'testifier': testifier,
      'testimony': testimony,
      'dateShared': Timestamp.fromDate(dateShared),
      'imageUrl': imageUrl,
    };
  }
}

class MockTestimonyData {
  static List<Map<String, dynamic>> getMockData() {
    final now = DateTime.now();
    return [
      {
        'testifier': 'Sarah Thompson',
        'testimony':
            'After three years of struggling with infertility, God blessed us with twins! The prayers of the church family have been answered. We are grateful for His perfect timing and mercy.',
        'dateShared': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'imageUrl': null,
      },
      {
        'testifier': 'James Wilson',
        'testimony':
            'I lost my job during the pandemic, but through the support of our church community and God\'s grace, I\'ve now found an even better position. God truly makes all things work together for good!',
        'dateShared': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'imageUrl': null,
      },
      {
        'testifier': 'Grace Chen',
        'testimony':
            'My mother was diagnosed with cancer last year. Our church family stood with us in prayer, and today she is completely cancer-free! The doctors are amazed, but we know it\'s God\'s healing power.',
        'dateShared': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'imageUrl': null,
      },
      {
        'testifier': 'Michael Roberts',
        'testimony':
            'Through the financial management course offered by our church, I was able to clear all my debts within a year. God\'s principles really work when we apply them!',
        'dateShared': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'imageUrl': null,
      },
      {
        'testifier': 'Rebecca Martinez',
        'testimony':
            'My marriage was on the brink of divorce, but through counseling with our pastors and God\'s intervention, my husband and I are now restored and stronger than ever. Nothing is impossible with God!',
        'dateShared': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'imageUrl': null,
      }
    ];
  }
}

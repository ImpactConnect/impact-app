import 'package:cloud_firestore/cloud_firestore.dart';

class MockData {
  static final List<Map<String, dynamic>> categories = [
    {'name': 'Sunday Service'},
    {'name': 'Bible Study'},
    {'name': 'Youth Service'},
    {'name': 'Special Service'},
    {'name': 'Revival'},
    {'name': 'Conference'},
    {'name': 'Workshop'},
  ];

  static final List<Map<String, dynamic>> preachers = [
    {
      'name': 'Pastor John Smith',
      'imageUrl': 'https://picsum.photos/seed/preacher1/300/300',
    },
    {
      'name': 'Rev. Sarah Johnson',
      'imageUrl': 'https://picsum.photos/seed/preacher2/300/300',
    },
    {
      'name': 'Dr. Michael Brown',
      'imageUrl': 'https://picsum.photos/seed/preacher3/300/300',
    },
    {
      'name': 'Elder David Wilson',
      'imageUrl': 'https://picsum.photos/seed/preacher4/300/300',
    },
    {
      'name': 'Pastor Mary Anderson',
      'imageUrl': 'https://picsum.photos/seed/preacher5/300/300',
    },
    {
      'name': 'Bishop James Williams',
      'imageUrl': 'https://picsum.photos/seed/preacher6/300/300',
    },
    {
      'name': 'Evangelist Grace Taylor',
      'imageUrl': 'https://picsum.photos/seed/preacher7/300/300',
    },
  ];

  static final List<Map<String, dynamic>> tags = [
    {'name': 'faith'},
    {'name': 'prayer'},
    {'name': 'worship'},
    {'name': 'healing'},
    {'name': 'salvation'},
    {'name': 'holy spirit'},
    {'name': 'love'},
    {'name': 'grace'},
    {'name': 'discipleship'},
    {'name': 'leadership'},
    {'name': 'family'},
    {'name': 'marriage'},
    {'name': 'youth'},
    {'name': 'evangelism'},
    {'name': 'missions'},
  ];

  static final List<Map<String, dynamic>> sermons = [
    {
      'title': 'Walking in Faith',
      'preacherName': 'Pastor John Smith',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon1/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'category': 'Sunday Service',
      'tags': ['faith', 'prayer', 'worship'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
    {
      'title': 'The Power of Prayer',
      'preacherName': 'Rev. Sarah Johnson',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon2/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      'category': 'Bible Study',
      'tags': ['prayer', 'holy spirit'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
    },
    {
      'title': 'Understanding God\'s Grace',
      'preacherName': 'Dr. Michael Brown',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon3/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'category': 'Sunday Service',
      'tags': ['grace', 'salvation'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
    },
    {
      'title': 'Youth Revival Night',
      'preacherName': 'Pastor Mary Anderson',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon4/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      'category': 'Youth Service',
      'tags': ['youth', 'worship', 'holy spirit'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
    },
    {
      'title': 'Building Strong Families',
      'preacherName': 'Elder David Wilson',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon5/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      'category': 'Workshop',
      'tags': ['family', 'marriage', 'love'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
    },
    {
      'title': 'Leadership in Ministry',
      'preacherName': 'Bishop James Williams',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon6/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      'category': 'Conference',
      'tags': ['leadership', 'discipleship'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6))),
    },
    {
      'title': 'Healing and Deliverance',
      'preacherName': 'Evangelist Grace Taylor',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon7/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      'category': 'Special Service',
      'tags': ['healing', 'faith', 'prayer'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
    },
    {
      'title': 'The Great Commission',
      'preacherName': 'Pastor John Smith',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon8/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
      'category': 'Sunday Service',
      'tags': ['evangelism', 'missions'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
    },
    {
      'title': 'Living in God\'s Love',
      'preacherName': 'Rev. Sarah Johnson',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon9/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      'category': 'Bible Study',
      'tags': ['love', 'grace', 'faith'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 9))),
    },
    {
      'title': 'Revival Fire',
      'preacherName': 'Dr. Michael Brown',
      'thumbnailUrl': 'https://picsum.photos/seed/sermon10/400/300',
      'audioUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
      'category': 'Revival',
      'tags': ['holy spirit', 'prayer', 'worship'],
      'dateCreated': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
    },
  ];

  static Future<void> populateFirestore() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();

    // Add categories
    for (final category in categories) {
      final ref = firestore.collection('categories').doc();
      batch.set(ref, category);
    }

    // Add preachers
    for (final preacher in preachers) {
      final ref = firestore.collection('preachers').doc();
      batch.set(ref, preacher);
    }

    // Add tags
    for (final tag in tags) {
      final ref = firestore.collection('tags').doc();
      batch.set(ref, tag);
    }

    // Add sermons
    for (final sermon in sermons) {
      final ref = firestore.collection('sermons').doc();
      batch.set(ref, sermon);
    }

    // Commit the batch
    await batch.commit();
    print('Mock data populated successfully!');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class MockDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> populateMockBlogPosts() async {
    final batch = _firestore.batch();
    final blogCollection = _firestore.collection('blog_posts');

    final mockPosts = [
      {
        'title': 'Finding Peace in Prayer: A Guide to Daily Devotion',
        'content': '''
Prayer is not just a religious routine; it's a vital connection to our Creator that brings peace, guidance, and strength to our daily lives. In this post, we'll explore practical ways to develop a meaningful prayer life that goes beyond mere words.

First, let's understand that prayer is a two-way conversation. It's not just about presenting our requests to God but also about listening to His voice. This requires creating a quiet space and time in our busy schedules where we can be still and know that He is God.

Here are some practical steps to enhance your prayer life:

1. Set aside a specific time each day
2. Create a dedicated prayer space
3. Start with gratitude
4. Be honest and authentic
5. Include Scripture in your prayers
6. Keep a prayer journal

Remember, consistency is more important than length. A sincere five-minute prayer can be more meaningful than an hour of distracted devotion.''',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1544764200-d834fd210a23',
        'imageUrl': 'https://images.unsplash.com/photo-1544764200-d834fd210a23',
        'author': 'Pastor John Smith',
        'datePosted': Timestamp.now(),
        'likes': 45,
        'tags': ['Prayer', 'Devotion', 'Spiritual Growth'],
      },
      {
        'title': 'Understanding Modern Worship: Bridging Tradition and Innovation',
        'content': '''
The landscape of church worship has evolved significantly over the years, bringing both excitement and challenges to our faith communities. This post explores how we can embrace contemporary worship while honoring our rich spiritual heritage.

Modern worship isn't about abandoning tradition; it's about making our eternal message relevant to today's believers. The key is finding the right balance that speaks to both young and mature Christians alike.

Here are some ways we're bridging the gap:

1. Incorporating both traditional hymns and contemporary songs
2. Using modern instruments while preserving sacred elements
3. Creating multimedia experiences that enhance rather than distract
4. Maintaining theological depth in modern expressions

The goal is to create an authentic worship experience that connects people with God, regardless of the style or format.''',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3',
        'imageUrl': 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3',
        'author': 'Sarah Johnson',
        'datePosted': Timestamp.now().toDate().subtract(const Duration(days: 2)),
        'likes': 38,
        'tags': ['Worship', 'Music', 'Church Life'],
      },
      {
        'title': 'Community Service: Living Out Our Faith',
        'content': '''
Faith without works is dead, as the Scripture tells us. In this post, we'll explore practical ways our church community is making a difference in our local area and how you can get involved.

Community service isn't just about helping others; it's about living out the gospel in tangible ways. When we serve others, we're showing Christ's love in action and building bridges that can lead to meaningful conversations about faith.

Current Community Initiatives:
1. Food bank partnerships
2. After-school tutoring programs
3. Senior citizen support
4. Homeless outreach
5. Environmental stewardship projects

Each of these programs provides unique opportunities to show God's love in practical ways. Whether you have an hour or a day to give, there's a place for you to serve.''',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1593113598332-cd288d649433',
        'imageUrl': 'https://images.unsplash.com/photo-1593113598332-cd288d649433',
        'author': 'David Wilson',
        'datePosted': Timestamp.now().toDate().subtract(const Duration(days: 5)),
        'likes': 72,
        'tags': ['Community', 'Service', 'Outreach'],
      },
    ];

    for (var post in mockPosts) {
      final docRef = blogCollection.doc();
      batch.set(docRef, post);
    }

    await batch.commit();
  }
}

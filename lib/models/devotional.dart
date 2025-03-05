import 'package:cloud_firestore/cloud_firestore.dart';

class Devotional {
  Devotional({
    required this.id,
    required this.topic,
    required this.date,
    required this.bibleVerse,
    required this.content,
    required this.prayerPoints,
    required this.author,
  });

  factory Devotional.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Devotional(
      id: doc.id,
      topic: data['topic'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      bibleVerse: data['bibleVerse'] ?? '',
      content: data['content'] ?? '',
      prayerPoints: List<String>.from(data['prayerPoints'] ?? []),
      author: data['author'] ?? '',
    );
  }
  final String id;
  final String topic;
  final DateTime date;
  final String bibleVerse;
  final String content;
  final List<String> prayerPoints;
  final String author;

  Map<String, dynamic> toFirestore() {
    return {
      'topic': topic,
      'date': Timestamp.fromDate(date),
      'bibleVerse': bibleVerse,
      'content': content,
      'prayerPoints': prayerPoints,
      'author': author,
    };
  }
}

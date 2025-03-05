import 'package:cloud_firestore/cloud_firestore.dart';

class LiveStream {
  LiveStream({
    required this.id,
    required this.title,
    required this.url,
    required this.platform,
    required this.isLive,
    required this.startTime,
    this.endTime,
  });

  factory LiveStream.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStream(
      id: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      platform: data['platform'] ?? 'youtube',
      isLive: data['isLive'] ?? false,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String title;
  final String url;
  final String platform; // 'youtube' or 'facebook'
  final bool isLive;
  final DateTime startTime;
  final DateTime? endTime;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'platform': platform,
      'isLive': isLive,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }
}

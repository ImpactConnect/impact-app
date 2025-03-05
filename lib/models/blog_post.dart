import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.author,
    required this.datePosted,
    required this.likes,
    required this.tags,
  });

  factory BlogPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlogPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      author: data['author'] ?? '',
      datePosted: (data['datePosted'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
  final String id;
  final String title;
  final String content;
  final String thumbnailUrl;
  final String imageUrl;
  final String author;
  final DateTime datePosted;
  final int likes;
  final List<String> tags;

  // Generate an excerpt from the content
  String get excerpt {
    if (content.length <= 100) {
      return content;
    }
    return '${content.substring(0, 100)}...';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': imageUrl,
      'author': author,
      'datePosted': Timestamp.fromDate(datePosted),
      'likes': likes,
      'tags': tags,
    };
  }
}

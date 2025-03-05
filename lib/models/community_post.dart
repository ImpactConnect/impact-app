import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  // Convert Firestore document to CommunityPost object
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['author_id'] ?? '',
      authorName: data['author_name'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
      likesCount: data['likes_count'] ?? 0,
      commentsCount: data['comments_count'] ?? 0,
    );
  }
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final int likesCount;
  final int commentsCount;

  // Convert CommunityPost to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt,
      'likes_count': likesCount,
      'comments_count': commentsCount,
    };
  }

  // Get a preview of the content (first 100 characters)
  String get contentPreview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}

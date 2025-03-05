import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  // For nested comments/replies

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.parentCommentId,
  });

  // Convert Firestore document to CommunityComment object
  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityComment(
      id: doc.id,
      postId: data['post_id'] ?? '',
      authorId: data['author_id'] ?? '',
      authorName: data['author_name'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
      likesCount: data['likes_count'] ?? 0,
      parentCommentId: data['parent_comment_id'],
    );
  }
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final Timestamp createdAt;
  final int likesCount;
  final String? parentCommentId;

  // Convert CommunityComment to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'content': content,
      'created_at': createdAt,
      'likes_count': likesCount,
      'parent_comment_id': parentCommentId,
    };
  }

  // Format time for display
  String get formattedTime {
    final DateTime dateTime = createdAt.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

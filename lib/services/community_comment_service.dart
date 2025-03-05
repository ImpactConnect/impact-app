import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_comment.dart';
import '../models/community_user.dart';

class CommunityCommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new comment
  Future<CommunityComment?> addComment({
    required CommunityUser author,
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    print('CommunityCommentService: Adding Comment');
    print('Author: ${author.id}, ${author.displayName}');
    print('Post ID: $postId');
    print('Content: $content');
    print('Parent Comment ID: $parentCommentId');

    try {
      // Create comment document
      final DocumentReference commentRef =
          _firestore.collection('community_comments').doc();

      final CommunityComment newComment = CommunityComment(
        id: commentRef.id,
        postId: postId,
        authorId: author.id,
        authorName: author.displayName,
        content: content,
        createdAt: Timestamp.now(),
        likesCount: 0, // Initialize likes count
        parentCommentId: parentCommentId,
      );

      print('New Comment Object Created: ${newComment.toFirestore()}');

      // First, get the current comment count
      final DocumentReference postRef =
          _firestore.collection('community_posts').doc(postId);
      final DocumentSnapshot postSnapshot = await postRef.get();

      final int currentCommentCount = postSnapshot['comments_count'] ?? 0;
      print('Current Comment Count: $currentCommentCount');

      // Add the comment and update post's comment count in a single transaction
      await _firestore.runTransaction((transaction) async {
        // Add the comment
        transaction.set(commentRef, newComment.toFirestore());

        // Update post's comment count
        transaction
            .update(postRef, {'comments_count': currentCommentCount + 1});
      });

      print('Comment Added Successfully: ${newComment.id}');
      return newComment;
    } catch (e) {
      print('CommunityCommentService: Error adding comment');
      print('Detailed Error: $e');
      return null;
    }
  }

  // Get comments for a specific post
  Stream<List<CommunityComment>> getComments(String postId) {
    return _firestore
        .collection('community_comments')
        .where('post_id', isEqualTo: postId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      print('Fetching comments for post: $postId');
      print('Number of comments found: ${snapshot.docs.length}');

      final comments = snapshot.docs
          .map((doc) => CommunityComment.fromFirestore(doc))
          .toList();

      for (var comment in comments) {
        print('Comment details: ${comment.content}, by ${comment.authorName}');
      }

      return comments;
    });
  }

  // Like a comment
  Future<bool> likeComment(String commentId, String userId) async {
    try {
      final DocumentReference commentRef =
          _firestore.collection('community_comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot commentSnapshot =
            await transaction.get(commentRef);

        if (!commentSnapshot.exists) {
          throw Exception('Comment does not exist');
        }

        final int currentLikes = commentSnapshot['likesCount'] ?? 0;
        transaction.update(commentRef, {'likesCount': currentLikes + 1});
      });

      return true;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Delete the comment
        final DocumentReference commentRef =
            _firestore.collection('community_comments').doc(commentId);
        transaction.delete(commentRef);

        // Decrement post's comment count
        final DocumentReference postRef =
            _firestore.collection('community_posts').doc(postId);
        final DocumentSnapshot postSnapshot = await transaction.get(postRef);

        final int currentCommentCount = postSnapshot['comments_count'] ?? 0;
        transaction.update(postRef, {
          'comments_count':
              currentCommentCount > 0 ? currentCommentCount - 1 : 0
        });
      });

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }
}

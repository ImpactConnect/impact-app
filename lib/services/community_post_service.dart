import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post.dart';
import '../models/community_user.dart';

class CommunityPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new post
  Future<CommunityPost?> createPost({
    required CommunityUser author,
    required String title,
    required String content,
  }) async {
    try {
      // Create post document
      final DocumentReference postRef =
          _firestore.collection('community_posts').doc();

      final CommunityPost newPost = CommunityPost(
        id: postRef.id,
        title: title,
        content: content,
        authorId: author.id,
        authorName: author.displayName,
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await postRef.set(newPost.toFirestore());

      return newPost;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // Get all posts (paginated)
  Stream<List<CommunityPost>> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('community_posts')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();
    });
  }

  // Like a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      // Implement like mechanism (could be a transaction)
      final DocumentReference postRef =
          _firestore.collection('community_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('Post does not exist');
        }

        final int currentLikes = postSnapshot['likes_count'] ?? 0;
        transaction.update(postRef, {'likes_count': currentLikes + 1});
      });

      return true;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Get post details
  Future<CommunityPost?> getPostById(String postId) async {
    try {
      final DocumentSnapshot postDoc =
          await _firestore.collection('community_posts').doc(postId).get();

      return CommunityPost.fromFirestore(postDoc);
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }
}

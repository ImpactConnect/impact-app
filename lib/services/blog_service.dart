import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'blog_posts';

  Stream<List<BlogPost>> getBlogPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('datePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
    });
  }

  Future<BlogPost> getBlogPost(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return BlogPost.fromFirestore(doc);
  }

  Future<void> incrementLikes(String postId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> decrementLikes(String postId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likes': FieldValue.increment(-1),
    });
  }

  Future<BlogPost?> getBlogPostById(String id) async {
    try {
      final doc = await _firestore.collection('blog_posts').doc(id).get();
      if (doc.exists) {
        return BlogPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting blog post: $e');
      return null;
    }
  }

  Future<List<BlogPost>> searchBlogPosts(String query) async {
    // Normalize query
    final normalizedQuery = query.toLowerCase().trim();
    
    try {
      // Get all blog posts and filter manually
      final snapshot = await _firestore
          .collection('blog_posts')
          .orderBy('datePosted', descending: true)
          .get();
      
      // Filter blog posts manually
      final List<BlogPost> matchingPosts = [];
      
      for (final doc in snapshot.docs) {
        try {
          final post = BlogPost.fromFirestore(doc);
          final title = post.title.toLowerCase();
          final content = post.content.toLowerCase();
          
          if (title.contains(normalizedQuery) || 
              content.contains(normalizedQuery)) {
            matchingPosts.add(post);
          }
        } catch (e) {
          // Skip this post if there's an error
          print('Error processing blog post: $e');
        }
      }
      
      return matchingPosts;
    } catch (e) {
      print('Error searching blog posts: $e');
      return [];
    }
  }
}

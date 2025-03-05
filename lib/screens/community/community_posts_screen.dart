import 'package:flutter/material.dart';

import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../services/community_post_service.dart';
import '../../widgets/bottom_nav_bar.dart'; // Corrected import path
import 'community_post_details_screen.dart';

class CommunityPostsScreen extends StatefulWidget {
  const CommunityPostsScreen({Key? key, required this.currentUser})
      : super(key: key);
  final CommunityUser currentUser;

  @override
  _CommunityPostsScreenState createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CommunityPostService _postService = CommunityPostService();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          'Create New Post',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width * 0.85, // 85% of screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Post Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.title),
                    counterText: '', // Hide character counter
                  ),
                  maxLength: 100,
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _postController,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.message),
                    counterText: '', // Hide character counter
                  ),
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _titleController.clear();
              _postController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createPost();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _postController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both title and post content')),
      );
      return;
    }

    try {
      await _postService.createPost(
        author: widget.currentUser,
        title: _titleController.text.trim(),
        content: _postController.text.trim(),
      );

      // Clear text fields
      _titleController.clear();
      _postController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _postController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Discussions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePostDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _postService.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet. Be the first to start a discussion!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Filter posts based on search query
          final filteredPosts = snapshot.data!.where((post) {
            final titleMatches =
                post.title.toLowerCase().contains(_searchQuery);
            final contentMatches =
                post.content.toLowerCase().contains(_searchQuery);
            return titleMatches || contentMatches;
          }).toList();

          return ListView.builder(
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return _buildPostCard(post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:
          const BottomNavBar(currentIndex: 2), // Set to Community index
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    // Format the date
    final DateTime postDate = post.createdAt.toDate();
    final String formattedDate = _formatPostDate(postDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          post.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.contentPreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  post.authorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                Text(' ${post.likesCount}'),
                const SizedBox(width: 8),
                const Icon(Icons.comment, size: 16),
                Text(' ${post.commentsCount}'),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to post details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityPostDetailsScreen(
                post: post,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to format post date
  String _formatPostDate(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inDays == 0) {
      // Today
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // More than a week ago, show date
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    }
  }
}

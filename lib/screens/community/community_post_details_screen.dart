import 'package:flutter/material.dart';

import '../../models/community_comment.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../services/community_comment_service.dart';
import '../../services/community_post_service.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  const CommunityPostDetailsScreen({
    Key? key,
    required this.post,
    required this.currentUser,
  }) : super(key: key);
  final CommunityPost post;
  final CommunityUser currentUser;

  @override
  _CommunityPostDetailsScreenState createState() =>
      _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState
    extends State<CommunityPostDetailsScreen> {
  final CommunityPostService _postService = CommunityPostService();
  final CommunityCommentService _commentService = CommunityCommentService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isLiked = false;
  CommunityComment? _replyingTo;

  Future<void> _likePost() async {
    final bool success =
        await _postService.likePost(widget.post.id, widget.currentUser.id);

    if (success) {
      setState(() {
        _isLiked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post liked!')),
      );
    }
  }

  Future<void> _submitComment() async {
    print('Submit Comment Called');
    print('Comment Text: ${_commentController.text}');
    print('Post ID: ${widget.post.id}');
    print('Current User: ${widget.currentUser.id}');
    print('Replying To: ${_replyingTo?.id}');

    if (_commentController.text.isEmpty) {
      print('Comment text is empty');
      return;
    }

    try {
      final comment = await _commentService.addComment(
        author: widget.currentUser,
        postId: widget.post.id,
        content: _commentController.text.trim(),
        parentCommentId: _replyingTo?.id,
      );

      print('Comment Added: ${comment?.id}');

      // Clear comment field and reset reply state
      _commentController.clear();
      setState(() {
        _replyingTo = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      print('Comment Submission Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  void _setReplyTo(CommunityComment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensure scaffold resizes for keyboard
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // App Bar
            AppBar(
              title: const Text('Discussion'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _sharePost,
                ),
              ],
            ),

            // Post Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic (Title)
                      Text(
                        widget.post.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),

                      // Author Information
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            child: Text(
                              widget.post.authorName[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                _formatPostDate(widget.post.createdAt.toDate()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Post Content
                      Text(
                        widget.post.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                      ),

                      // Interaction Bar
                      const SizedBox(height: 16),
                      _buildInteractionBar(),

                      const Divider(height: 32),

                      // Comments Section
                      _buildCommentSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Comment Input Bar
            _buildCommentInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 150, // Limit max height
                  minHeight: 50, // Minimum height
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null, // Allow multiple lines
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInteractionButton(
          icon: Icons.favorite_border,
          count: widget.post.likesCount,
          onTap: _toggleLike,
          activeIcon: Icons.favorite,
          isActive: _isLiked,
        ),
        _buildInteractionButton(
          icon: Icons.comment_outlined,
          count: widget.post.commentsCount,
          onTap: () {
            // Focus on comment input when tapped
            _commentFocusNode.requestFocus();
          },
        ),
        _buildInteractionButton(
          icon: Icons.share_outlined,
          onTap: _sharePost,
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    int? count,
    VoidCallback? onTap,
    IconData? activeIcon,
    bool isActive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon ?? icon : icon,
              color: isActive ? Colors.red : Colors.grey[600],
              size: 24,
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<CommunityComment>>(
          stream: _commentService.getComments(widget.post.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final comment = snapshot.data![index];
                return _buildCommentCard(comment);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentCard(CommunityComment comment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  comment.authorName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatCommentDate(comment.createdAt.toDate()),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format post date (similar to previous implementation)
  String _formatPostDate(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inDays == 0) {
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
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    }
  }

  // New method to format comment date with more granularity
  String _formatCommentDate(DateTime commentDate) {
    final now = DateTime.now();
    final difference = now.difference(commentDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${commentDate.day}/${commentDate.month}/${commentDate.year}';
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    _likePost();
  }

  void _sharePost() {
    // TODO: Implement post sharing
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
}

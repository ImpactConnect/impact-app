import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/blog_post.dart';
import '../../services/blog_service.dart';

class BlogDetailScreen extends StatelessWidget {
  BlogDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);
  final String postId;
  final BlogService _blogService = BlogService();

  void _shareBlogPost(BuildContext context, BlogPost post) {
    final url = 'https://yourchurch.com/blog/${post.id}';
    Share.share(
      '${post.title}\n\nRead more at: $url',
      subject: post.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<BlogPost>(
        future: _blogService.getBlogPost(postId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // App Bar with Hero Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'blog-image-${post.id}',
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      // Author and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likes}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                post.author,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                timeago.format(post.datePosted),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Content
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),

                      // Tags
                      Wrap(
                        spacing: 8,
                        children: post.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<BlogPost>(
              future: _blogService.getBlogPost(postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final post = snapshot.data!;
                return TextButton.icon(
                  onPressed: () async {
                    await _blogService.incrementLikes(postId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thanks for liking!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.favorite,
                    color: Theme.of(context).primaryColor,
                  ),
                  label: Text('Like (${post.likes})'),
                );
              },
            ),
            FutureBuilder<BlogPost>(
              future: _blogService.getBlogPost(postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return TextButton.icon(
                  onPressed: () => _shareBlogPost(context, snapshot.data!),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

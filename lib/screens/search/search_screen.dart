import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sermon.dart';
import '../../models/blog_post.dart';
import '../../services/sermon_service.dart';
import '../../services/blog_service.dart';
import '../../widgets/sermon_card.dart';
import '../../main.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({
    Key? key,
    this.initialQuery = '',
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _isLoading = false;

  // Search results
  List<Sermon> _sermons = [];
  List<BlogPost> _blogPosts = [];
  List<DocumentSnapshot> _preachers = [];
  List<DocumentSnapshot> _books = [];
  List<DocumentSnapshot> _devotionals = [];
  List<DocumentSnapshot> _videos = [];
  List<DocumentSnapshot> _library = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    
    // Schedule focus request after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
    
    if (_query.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Search sermons
      final sermonService = MyApp.of(context).sermonService;
      final sermons = await sermonService.searchSermons(_query);
      
      // Search blog posts
      final blogService = MyApp.of(context).blogService;
      final blogPosts = await blogService.searchBlogPosts(_query);
      
      // Search preachers - handle case where fields might not exist
      final preachersSnapshot = await FirebaseFirestore.instance
          .collection('preachers')
          .get();
      
      // Filter preachers manually since the fields might not be indexed
      final filteredPreachers = preachersSnapshot.docs.where((doc) {
        try {
          final name = doc.get('name') as String? ?? '';
          return name.toLowerCase().contains(_query.toLowerCase());
        } catch (e) {
          return false;
        }
      }).toList();
      
      // Search library/ebooks
      final librarySnapshot = await FirebaseFirestore.instance
          .collection('library')
          .get();
          
      print('Library search - Total documents: ${librarySnapshot.docs.length}');
      
      // Print all library documents for debugging
      for (var doc in librarySnapshot.docs) {
        try {
          print('Library document ID: ${doc.id}');
          print('Library fields: ${doc.data()}');
        } catch (e) {
          print('Error printing library data: $e');
        }
      }
      
      final filteredLibrary = librarySnapshot.docs.where((doc) {
        try {
          final title = doc.get('title') as String? ?? '';
          final author = doc.get('author') as String? ?? '';
          final description = doc.get('description') as String? ?? '';
          final category = doc.get('category') as String? ?? '';
          
          final matchesQuery = title.toLowerCase().contains(_query.toLowerCase()) ||
                              author.toLowerCase().contains(_query.toLowerCase()) ||
                              description.toLowerCase().contains(_query.toLowerCase()) ||
                              category.toLowerCase().contains(_query.toLowerCase());
                              
          if (matchesQuery) {
            print('MATCHED LIBRARY ITEM: ${doc.id} - Title: $title');
          }
          
          return matchesQuery;
        } catch (e) {
          print('Error filtering library item: ${doc.id}, Error: $e');
          return false;
        }
      }).toList();
      
      print('Library search - Filtered count: ${filteredLibrary.length}');
      
      // Search devotionals
      final devotionalsSnapshot = await FirebaseFirestore.instance
          .collection('devotionals')
          .get();
          
      print('Devotionals search - Total documents: ${devotionalsSnapshot.docs.length}');
      
      // Print all devotional documents for debugging
      for (var doc in devotionalsSnapshot.docs) {
        try {
          print('Devotional document ID: ${doc.id}');
          print('Devotional fields: ${doc.data()}');
        } catch (e) {
          print('Error printing devotional data: $e');
        }
      }
      
      final filteredDevotionals = devotionalsSnapshot.docs.where((doc) {
        try {
          final title = doc.get('title') as String? ?? '';
          final author = doc.get('author') as String? ?? '';
          final content = doc.get('content') as String? ?? '';
          
          final matchesQuery = title.toLowerCase().contains(_query.toLowerCase()) ||
                              author.toLowerCase().contains(_query.toLowerCase()) ||
                              content.toLowerCase().contains(_query.toLowerCase());
                              
          if (matchesQuery) {
            print('MATCHED DEVOTIONAL: ${doc.id} - Title: $title');
          }
          
          return matchesQuery;
        } catch (e) {
          print('Error filtering devotional: ${doc.id}, Error: $e');
          return false;
        }
      }).toList();
      
      print('Devotionals search - Filtered count: ${filteredDevotionals.length}');

      // Search videos
      final videosSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .get();
          
      print('Videos search - Total documents: ${videosSnapshot.docs.length}');
      
      // Print all video documents for debugging
      for (var doc in videosSnapshot.docs) {
        try {
          print('Video document ID: ${doc.id}');
          print('Video fields: ${doc.data()}');
        } catch (e) {
          print('Error printing video data: $e');
        }
      }
      
      final filteredVideos = videosSnapshot.docs.where((doc) {
        try {
          final title = doc.get('title') as String? ?? '';
          final description = doc.get('description') as String? ?? '';
          final speaker = doc.get('speaker') as String? ?? '';
          
          final matchesQuery = title.toLowerCase().contains(_query.toLowerCase()) ||
                              description.toLowerCase().contains(_query.toLowerCase()) ||
                              speaker.toLowerCase().contains(_query.toLowerCase());
                              
          if (matchesQuery) {
            print('MATCHED VIDEO: ${doc.id} - Title: $title');
          }
          
          return matchesQuery;
        } catch (e) {
          print('Error filtering video: ${doc.id}, Error: $e');
          return false;
        }
      }).toList();
      
      print('Videos search - Filtered count: ${filteredVideos.length}');

      setState(() {
        _sermons = sermons;
        _blogPosts = blogPosts;
        _preachers = filteredPreachers;
        _library = filteredLibrary;
        _devotionals = filteredDevotionals;
        _videos = filteredVideos;
        _isLoading = false;
      });
      
      // Add debug prints to check result counts
      print('Search results - Sermons: ${sermons.length}');
      print('Search results - Blog Posts: ${blogPosts.length}');
      print('Search results - Preachers: ${filteredPreachers.length}');
      print('Search results - Library: ${filteredLibrary.length}');
      print('Search results - Devotionals: ${filteredDevotionals.length}');
      print('Search results - Videos: ${filteredVideos.length}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          focusNode: _searchFocusNode,
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search sermons, blogs, preachers...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          onSubmitted: (value) {
            setState(() {
              _query = value.trim();
            });
            _performSearch();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _sermons = [];
                _blogPosts = [];
                _preachers = [];
                _library = [];
                _devotionals = [];
                _videos = [];
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _query = _searchController.text.trim();
              });
              _performSearch();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Search for sermons, blogs, preachers, and more',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    if (_sermons.isNotEmpty) ...[
                      _buildSectionHeader('Sermons', _sermons.length),
                      ..._sermons.map((sermon) => _buildSermonItem(sermon)).toList(),
                    ],
                    
                    if (_blogPosts.isNotEmpty) ...[
                      _buildSectionHeader('Blog Posts', _blogPosts.length),
                      ..._blogPosts.map((post) => _buildBlogItem(post)).toList(),
                    ],
                    
                    if (_library.isNotEmpty) ...[
                      _buildSectionHeader('Library', _library.length),
                      ..._library.map((book) => _buildBookItem(book)).toList(),
                    ],
                    
                    if (_preachers.isNotEmpty) ...[
                      _buildSectionHeader('Preachers', _preachers.length),
                      ..._preachers.map((preacher) => _buildPreacherItem(preacher)).toList(),
                    ],
                    
                    if (_devotionals.isNotEmpty) ...[
                      _buildSectionHeader('Devotionals', _devotionals.length),
                      ..._devotionals.map((devotional) => _buildDevotionalItem(devotional)).toList(),
                    ],
                    
                    if (_videos.isNotEmpty) ...[
                      _buildSectionHeader('Videos', _videos.length),
                      ..._videos.map((video) => _buildVideoItem(video)).toList(),
                    ],
                  ],
                ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_query"',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            '$count results',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSermonItem(Sermon sermon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.mic, color: Colors.blue[800]),
        ),
        title: Text(
          sermon.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'By ${sermon.preacherName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${sermon.dateCreated.toString().substring(0, 10)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/sermons',
            arguments: {'initialSermonId': sermon.id},
          );
        },
      ),
    );
  }

  Widget _buildBlogItem(BlogPost post) {
    return ListTile(
      leading: post.thumbnailUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                post.thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
              ),
            )
          : Container(
              width: 56,
              height: 56,
              color: Colors.blue[100],
              child: Icon(Icons.article, color: Colors.blue),
            ),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.excerpt,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/blog/detail',
          arguments: {'postId': post.id},
        );
      },
    );
  }

  Widget _buildPreacherItem(DocumentSnapshot preacher) {
    final name = preacher.get('name') as String;
    String? imageUrl;
    try {
      imageUrl = preacher.get('imageUrl') as String?;
    } catch (e) {
      imageUrl = null;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Text(name[0], style: TextStyle(fontSize: 20))
            : null,
      ),
      title: Text(name),
      subtitle: Text('Preacher'),
      onTap: () {
        // Navigate to preacher detail or filtered sermons by preacher
      },
    );
  }

  Widget _buildBookItem(DocumentSnapshot book) {
    String title = "Unknown Title";
    try {
      title = book.get('title') as String? ?? "Unknown Title";
    } catch (e) {
      print('Error getting book title: $e');
    }
    
    String? author;
    try {
      author = book.get('author') as String?;
    } catch (e) {
      print('Error getting book author: $e');
    }
    
    String? coverUrl;
    try {
      coverUrl = book.get('coverUrl') as String?;
      if (coverUrl == null) {
        coverUrl = book.get('imageUrl') as String?;
      }
    } catch (e) {
      print('Error getting book coverUrl: $e');
    }
    
    String? description;
    try {
      description = book.get('description') as String?;
    } catch (e) {
      // Silently ignore
    }
    
    String? category;
    try {
      category = book.get('category') as String?;
    } catch (e) {
      // Silently ignore
    }
    
    String? publishYear;
    try {
      publishYear = book.get('publishYear') as String?;
    } catch (e) {
      // Silently ignore
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: coverUrl != null && coverUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  coverUrl,
                  width: 56,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Container(
                        width: 56,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.book, color: Colors.grey),
                      ),
                ),
              )
            : Container(
                width: 56,
                height: 80,
                color: Colors.blue[100],
                child: Icon(Icons.book, color: Colors.blue),
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null && author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'By $author',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (category != null && category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Category: $category',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (publishYear != null && publishYear.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Published: $publishYear',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/library',
            arguments: {'bookId': book.id},
          );
        },
      ),
    );
  }

  Widget _buildDevotionalItem(DocumentSnapshot devotional) {
    String title = "Unknown Title";
    try {
      title = devotional.get('title') as String? ?? "Unknown Title";
    } catch (e) {
      print('Error getting devotional title: $e');
    }
    
    String? imageUrl;
    try {
      imageUrl = devotional.get('imageUrl') as String?;
    } catch (e) {
      print('Error getting devotional imageUrl: $e');
    }
    
    String? author;
    try {
      author = devotional.get('author') as String?;
    } catch (e) {
      print('Error getting devotional author: $e');
    }
    
    String? content;
    try {
      content = devotional.get('content') as String?;
    } catch (e) {
      // Silently ignore
    }
    
    String? date;
    try {
      final timestamp = devotional.get('date');
      if (timestamp is Timestamp) {
        date = timestamp.toDate().toString().substring(0, 10);
      }
    } catch (e) {
      // Silently ignore
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: imageUrl != null && imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: Icon(Icons.book, color: Colors.grey),
                      ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: Colors.purple[100],
                child: Icon(Icons.book, color: Colors.purple),
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null && author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'By $author',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                'Date: $date',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (content != null && content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/devotionals',
            arguments: {'devotionalId': devotional.id},
          );
        },
      ),
    );
  }

  Widget _buildVideoItem(DocumentSnapshot video) {
    String title = "Unknown Title";
    try {
      title = video.get('title') as String? ?? "Unknown Title";
    } catch (e) {
      print('Error getting video title: $e');
    }
    
    String? thumbnailUrl;
    try {
      thumbnailUrl = video.get('thumbnailUrl') as String?;
    } catch (e) {
      print('Error getting video thumbnailUrl: $e');
    }
    
    String? description;
    try {
      description = video.get('description') as String?;
    } catch (e) {
      print('Error getting video description: $e');
    }
    
    String? speaker;
    try {
      speaker = video.get('speaker') as String?;
    } catch (e) {
      print('Error getting video speaker: $e');
    }
    
    String? duration;
    try {
      duration = video.get('duration') as String?;
    } catch (e) {
      // Silently ignore
    }
    
    String? date;
    try {
      final timestamp = video.get('date');
      if (timestamp is Timestamp) {
        date = timestamp.toDate().toString().substring(0, 10);
      }
    } catch (e) {
      // Silently ignore
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: thumbnailUrl != null && thumbnailUrl.isNotEmpty
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      thumbnailUrl,
                      width: 80,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          Container(
                            width: 80,
                            height: 56,
                            color: Colors.grey[300],
                            child: Icon(Icons.videocam, color: Colors.grey),
                          ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                width: 80,
                height: 56,
                color: Colors.red[100],
                child: Icon(Icons.videocam, color: Colors.red),
              ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (speaker != null && speaker.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Speaker: $speaker',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            Row(
              children: [
                if (duration != null && duration.isNotEmpty) ...[
                  Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                ],
                if (date != null) ...[
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/videos',
            arguments: {'videoId': video.id},
          );
        },
      ),
    );
  }
}

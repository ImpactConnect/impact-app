import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../models/video_item.dart';
import '../../services/video_service.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoService _videoService = VideoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Currently selected video for in-app playback
  VideoItem? _selectedVideo;

  // Stream controllers for video lists
  final _recommendedVideosController =
      StreamController<List<VideoItem>>.broadcast();
  final _allVideosController = StreamController<List<VideoItem>>.broadcast();

  // Streams for videos
  late Stream<List<VideoItem>> _recommendedVideosStream;
  late Stream<List<VideoItem>> _allVideosStream;

  YoutubePlayerController? _youtubeController;

  // Helper method to generate YouTube thumbnail URL with more robust error handling
  String _generateYouTubeThumbnail(String videoUrl) {
    try {
      // More comprehensive regex to extract YouTube video ID
      final RegExp regExp = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=))([\w-]{11})(?:\S*)?',
        caseSensitive: false,
      );

      final Match? match = regExp.firstMatch(videoUrl);

      if (match != null && match.group(1) != null) {
        final videoId = match.group(1)!;

        // Debug prints
        print('Original Video URL: $videoUrl');
        print('Extracted YouTube Video ID: $videoId');

        // Return maxres thumbnail URL
        final thumbnailUrl =
            'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
        print('Generated YouTube Thumbnail URL: $thumbnailUrl');

        return thumbnailUrl;
      } else {
        print('Failed to extract YouTube video ID from URL: $videoUrl');
      }
    } catch (e) {
      print('Error generating YouTube thumbnail: $e');
    }

    // Fallback placeholder with debug information
    const fallbackUrl =
        'https://via.placeholder.com/1280x720.png?text=Invalid+YouTube+URL';
    print('Using fallback thumbnail URL: $fallbackUrl');
    return fallbackUrl;
  }

  // Helper method to generate thumbnail based on video type
  String _generateThumbnailUrl(String videoUrl, String videoType) {
    try {
      switch (videoType) {
        case 'youtube':
          return _generateYouTubeThumbnail(videoUrl);
        case 'facebook':
          // Placeholder for Facebook video thumbnails
          return 'https://via.placeholder.com/1280x720.png?text=Facebook+Video';
        case 'network':
          // Placeholder for network video thumbnails
          return 'https://via.placeholder.com/1280x720.png?text=Network+Video';
        default:
          return 'https://via.placeholder.com/1280x720.png?text=Unknown+Video+Type';
      }
    } catch (e) {
      print('Error in thumbnail generation: $e');
      return 'https://via.placeholder.com/1280x720.png?text=Thumbnail+Error';
    }
  }

  // Mock data upload method with enhanced thumbnail generation
  Future<void> _uploadMockVideoData() async {
    try {
      // Prepare mock video data with dynamic thumbnails
      final List<Map<String, dynamic>> mockVideos = [
        {
          'id': 'mock_video_1',
          'title': 'Sunday Sermon: Embracing Faith',
          'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'videoType': 'youtube',
          'category': 'Sermon',
        },
        {
          'id': 'mock_video_2',
          'title': 'Worship Night: Praise and Worship',
          'videoUrl': 'https://www.youtube.com/watch?v=1F_nfBYYoco&t=87s',
          'videoType': 'youtube',
          'category': 'Worship',
        },
        {
          'id': 'mock_video_3',
          'title': 'Youth Ministry: Finding Your Purpose',
          'videoUrl': 'https://www.youtube.com/watch?v=pQn-pnXPaVg',
          'videoType': 'youtube',
          'category': 'Youth',
        },
        {
          'id': 'mock_video_4',
          'title': 'Network Video: Church Community Event',
          'videoUrl': 'https://example.com/network_video.mp4',
          'videoType': 'network',
          'category': 'Community',
        },
        {
          'id': 'mock_video_5',
          'title': 'Facebook Live: Sunday Service',
          'videoUrl': 'https://www.facebook.com/churchpage/videos/sample-video',
          'videoType': 'facebook',
          'category': 'Live Service',
        }
      ];

      // Batch write to Firestore
      final batch = _firestore.batch();
      for (var videoData in mockVideos) {
        // Debug: Print video URL and type
        print('Processing video: ${videoData['title']}');
        print('Video URL: ${videoData['videoUrl']}');
        print('Video Type: ${videoData['videoType']}');

        // Generate thumbnail URL with enhanced logging
        final thumbnailUrl = _generateThumbnailUrl(
            videoData['videoUrl'], videoData['videoType']);

        // Debug: Print generated thumbnail URL
        print('Generated Thumbnail URL: $thumbnailUrl');

        // Create complete video document
        final videoDocument = {
          'id': videoData['id'],
          'title': videoData['title'],
          'videoUrl': videoData['videoUrl'],
          'thumbnailUrl': thumbnailUrl,
          'views': 0,
          'likes': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'isRecommended': videoData['category'] != 'Network',
          'videoType': videoData['videoType'],
          'category': videoData['category'],
          'developmentMode': true,
        };

        final docRef = _firestore.collection('videos').doc(videoData['id']);
        batch.set(docRef, videoDocument);
      }

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock video data uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading mock data: $e')),
      );
      // Debug: Print full error details
      print('Full error details: $e');
    }
  }

  // Refresh method for videos
  Future<void> _refreshVideos() async {
    try {
      // Fetch recommended videos
      final recommendedSnapshot = await _firestore
          .collection('videos')
          .where('isRecommended', isEqualTo: true)
          .get();

      final recommendedVideos = recommendedSnapshot.docs.map((doc) {
        final data = doc.data();
        return VideoItem(
          id: data['id'],
          title: data['title'],
          thumbnailUrl: data['thumbnailUrl'],
          videoUrl: data['videoUrl'],
          views: data['views'] ?? 0,
          likes: data['likes'] ?? 0,
          postedDate:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Fetch all videos
      final allVideosSnapshot = await _firestore.collection('videos').get();

      final allVideos = allVideosSnapshot.docs.map((doc) {
        final data = doc.data();
        return VideoItem(
          id: data['id'],
          title: data['title'],
          thumbnailUrl: data['thumbnailUrl'],
          videoUrl: data['videoUrl'],
          views: data['views'] ?? 0,
          likes: data['likes'] ?? 0,
          postedDate:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Add to stream controllers
      _recommendedVideosController.add(recommendedVideos);
      _allVideosController.add(allVideos);
    } catch (e) {
      print('Error refreshing videos: $e');
      // Optionally show an error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh videos: $e')),
      );
    }
  }

  Future<void> _likeVideo(VideoItem video) async {
    try {
      // Reference to the specific video document
      final videoRef = _firestore.collection('videos').doc(video.id);

      // Increment likes in Firestore
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(videoRef);

        if (!snapshot.exists) {
          throw Exception('Video does not exist!');
        }

        // Get current likes and increment
        final currentLikes = snapshot.data()?['likes'] ?? 0;
        transaction.update(videoRef, {
          'likes': currentLikes + 1,
        });

        // Update local state
        setState(() {
          _selectedVideo = _selectedVideo?.copyWith(likes: currentLikes + 1);
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video liked!')),
        );
      });
    } catch (e) {
      print('Error liking video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like video: $e')),
      );
    }
  }

  Future<void> _playVideo(VideoItem video) async {
    try {
      // Increment view count
      await _videoService.incrementVideoViews(video.id);

      // Extract YouTube video ID
      final String? videoId =
          YoutubePlayerController.convertUrlToId(video.videoUrl);

      if (videoId == null) {
        // If not a valid YouTube URL, launch externally
        _launchExternalVideo(video);
        return;
      }

      // Set selected video
      setState(() {
        _selectedVideo = video;
      });

      // Initialize YouTube Player Controller with custom options
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          showVideoAnnotations: false,
          enableJavaScript: true,
        ),
      );

      // Allow both portrait and landscape orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Navigate to full-screen video player
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                _selectedVideo!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: Center(
              child: YoutubePlayerScaffold(
                controller: _youtubeController!,
                builder: (context, player) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      player,
                      // Video details section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StreamBuilder<int>(
                                  stream: _videoService
                                      .getVideoViews(_selectedVideo!.id),
                                  builder: (context, snapshot) {
                                    final views =
                                        snapshot.data ?? _selectedVideo!.views;
                                    return Text(
                                      '${_formatViews(views)} • ${_formatDate(_selectedVideo!.postedDate)} • ${_selectedVideo!.likes} likes',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up),
                                      onPressed: () =>
                                          _likeVideo(_selectedVideo!),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Share feature coming soon')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error playing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play video: $e')),
      );
    }
  }

  Future<void> _launchExternalVideo(VideoItem video) async {
    final Uri videoUri = Uri.parse(video.videoUrl);
    if (await canLaunchUrl(videoUri)) {
      await launchUrl(
        videoUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      _showErrorSnackBar('Could not launch video');
    }
  }

  Widget _buildVideoPlayerBottomSheet() {
    if (_youtubeController == null || _selectedVideo == null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.8,
      maxChildSize: 1.0,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      _selectedVideo!.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black),
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Share feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  YoutubePlayer(
                    controller: _youtubeController!,
                    aspectRatio: 16 / 9,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<int>(
                          stream:
                              _videoService.getVideoViews(_selectedVideo!.id),
                          builder: (context, snapshot) {
                            final views =
                                snapshot.data ?? _selectedVideo!.views;
                            return Text(
                              '${_formatViews(views)} • ${_formatDate(_selectedVideo!.postedDate)} • ${_selectedVideo!.likes} likes',
                              style: const TextStyle(color: Colors.grey),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInteractionButton(
                              icon: Icons.thumb_up_outlined,
                              label: 'Like',
                              onPressed: () {
                                // TODO: Implement like functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Like feature coming soon')),
                                );
                              },
                            ),
                            _buildInteractionButton(
                              icon: Icons.comment_outlined,
                              label: 'Comment',
                              onPressed: () {
                                // TODO: Implement comment functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Comment feature coming soon')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Image.asset(
          'assets/images/video_header.jpg',
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore inspiring sermons, worship sessions, and ministry highlights',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue,
        backgroundColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  // Update video item to have full card height thumbnail
  Widget _buildVideoItem(VideoItem video) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(0), // Remove default padding
        leading: AspectRatio(
          aspectRatio: 16 / 9, // Maintain 16:9 aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            video.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: StreamBuilder<int>(
            stream: _videoService.getVideoViews(video.id),
            builder: (context, snapshot) {
              final views = snapshot.data ?? video.views;
              return Text(
                '${_formatViews(views)} • ${_formatDate(video.postedDate)} • ${video.likes} likes',
                style: const TextStyle(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        onTap: () => _playVideo(video),
      ),
    );
  }

  Widget _buildRecommendedVideosRow(List<VideoItem> recommendedVideos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: recommendedVideos.map((video) {
            return Container(
              width: 250,
              margin: const EdgeInsets.only(right: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                onPressed: () => _playVideo(video),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatViews(video.views)} • ${_formatDate(video.postedDate)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize video streams
    _recommendedVideosStream = _recommendedVideosController.stream;
    _allVideosStream = _allVideosController.stream;

    // Initial load
    _refreshVideos();
  }

  @override
  void dispose() {
    // Reset orientation to default
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _youtubeController?.close();
    _recommendedVideosController.close();
    _allVideosController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshVideos,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeroSection(),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recommended Videos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Recommended Videos Row
              SliverToBoxAdapter(
                child: StreamBuilder<List<VideoItem>>(
                  stream: _recommendedVideosStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No recommended videos'));
                    }

                    return _buildRecommendedVideosRow(snapshot.data!);
                  },
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'All Videos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // All Videos List
              StreamBuilder<List<VideoItem>>(
                stream: _allVideosStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Text('No videos available')),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildVideoItem(snapshot.data![index]),
                      childCount: snapshot.data!.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

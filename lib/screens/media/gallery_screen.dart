import 'dart:io' show Platform, File, Directory;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Download image to device
  Future<void> _downloadImage(String imageUrl, String fileName) async {
    try {
      // Request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android, request multiple storage-related permissions
        status = await Permission.storage.request();
        
        // If storage permission is denied, try requesting individual permissions
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
      } else if (Platform.isIOS) {
        // For iOS, request photo library permissions
        status = await Permission.photos.request();
      } else {
        // Unsupported platform
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download not supported on this platform')),
        );
        return;
      }
      
      // Check permission status
      if (status.isGranted) {
        // Download image
        final response = await http.get(Uri.parse(imageUrl));

        // Get appropriate directory
        final Directory? tempDir = Platform.isAndroid 
          ? await getExternalStorageDirectory() 
          : await getApplicationDocumentsDirectory();

        if (tempDir == null) {
          throw Exception('Could not access storage');
        }

        // Create file path
        final String filePath = '${tempDir.path}/$fileName.jpg';
        final File file = File(filePath);

        // Write file
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to $filePath')),
        );
      } else if (status.isDenied) {
        // Show a snackbar if permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download images'),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (status.isPermanentlyDenied) {
        // Redirect to app settings if permission is permanently denied
        await openAppSettings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  // Share image
  Future<void> _shareImage(String imageUrl, String title) async {
    try {
      // Download image temporarily
      final response = await http.get(Uri.parse(imageUrl));
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/shared_image.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Share
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: title,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  // Show full image in a popup
  void _showFullImagePopup(BuildContext context, Map<String, dynamic> imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Full Image
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageData['imageUrl'],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),

              // Download Icon (Bottom Left)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadImage(
                      imageData['imageUrl'], 
                      imageData['title'] ?? 'church_image'
                    ),
                  ),
                ),
              ),

              // Share Icon (Bottom Right)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => _shareImage(
                      imageData['imageUrl'], 
                      imageData['title'] ?? 'Church Image'
                    ),
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Church Gallery', style: TextStyle(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/gallery_header.jpg',
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better text visibility
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, category, or tags',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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

          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('gallery').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('No images in gallery')),
                  );
                }

                // Filter images based on search query
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final category = (data['category'] as String? ?? '').toLowerCase();
                  final tags = (data['tags'] as List? ?? [])
                      .map((tag) => tag.toString().toLowerCase())
                      .toList();

                  return _searchQuery.isEmpty || 
                         title.contains(_searchQuery) || 
                         category.contains(_searchQuery) ||
                         tags.any((tag) => tag.contains(_searchQuery));
                }).toList();

                if (filteredDocs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No images match your search',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final imageData = filteredDocs[index].data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () => _showFullImagePopup(context, imageData),
                        child: CachedNetworkImage(
                          imageUrl: imageData['imageUrl'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

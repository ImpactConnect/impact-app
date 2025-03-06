import 'package:flutter/material.dart';

import '../models/sermon.dart';
import '../services/ad_service.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';
import '../widgets/ads/banner_ad_widget.dart';
import '../widgets/mini_player.dart';
import '../widgets/sermon_card.dart';
import '../widgets/bottom_nav_bar.dart'; // Import the BottomNavBar widget
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SermonScreen extends StatefulWidget {
  const SermonScreen({
    Key? key,
    required this.sermonService,
    required this.audioPlayerService,
    this.initialSermonId,
    this.initialCategory,
    this.initialPreacher,
  }) : super(key: key);
  final SermonService sermonService;
  final AudioPlayerService audioPlayerService;
  final String? initialSermonId;
  final String? initialCategory;
  final String? initialPreacher;

  @override
  State<SermonScreen> createState() => _SermonScreenState();
}

class _SermonScreenState extends State<SermonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPreacher;
  String? _selectedTag;
  List<String> _categories = [];
  List<String> _preachers = [];
  List<String> _tags = [];
  bool _isLoading = true;
  String? _error;
  bool _showMiniPlayer = false;
  Sermon? _currentSermon;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final AdService _adService = AdService();

  Future<void> _handleRefresh() async {
    // Trigger a rebuild of the StreamBuilder
    setState(() {
      // Reset any filters or search
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = null;
      _selectedPreacher = null;
      _selectedTag = null;
    });
    // Add a small delay to make the refresh animation more noticeable
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    // Play initial sermon if ID is provided
    if (widget.initialSermonId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playInitialSermon();
      });
    }
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
    if (widget.initialPreacher != null) {
      _selectedPreacher = widget.initialPreacher;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final sermons = await widget.sermonService.getSermons();
      
      // Extract categories, preachers, and tags from sermons
      final categorySet = <String>{};
      final preacherSet = <String>{};
      final tagSet = <String>{};
      
      for (final sermon in sermons) {
        categorySet.add(sermon.category);
        preacherSet.add(sermon.preacherName);
        for (final tag in sermon.tags) {
          tagSet.add(tag);
        }
      }
      
      if (mounted) {
        setState(() {
          _categories = categorySet.toList()..sort();
          _preachers = preacherSet.toList()..sort();
          _tags = tagSet.toList()..sort();
          
          // Apply initial filters if provided
          if (widget.initialCategory != null) {
            _selectedCategory = widget.initialCategory;
          }
          
          if (widget.initialPreacher != null) {
            _selectedPreacher = widget.initialPreacher;
          }
          
          _isLoading = false;
        });
      }
      
      // Play initial sermon if provided
      if (widget.initialSermonId != null) {
        _playInitialSermon();
      }
      
      // Force a rebuild to ensure the UI reflects the latest data
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPreacher = null;
      _selectedTag = null;
    });
  }

  void _playSermon(Sermon sermon, List<Sermon> playlist) {
    setState(() {
      _showMiniPlayer = true;
      _currentSermon = sermon;
    });
    // The click count is already incremented in the SermonCard onTap
    widget.audioPlayerService.playSermonFromPlaylist(sermon, playlist);
    // Trigger a refresh after a short delay to update the UI with new counter values
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _closeMiniPlayer() {
    setState(() {
      _showMiniPlayer = false;
      _currentSermon = null;
    });
    widget.audioPlayerService.stop();
  }

  Future<void> _playInitialSermon() async {
    try {
      final sermon =
          await widget.sermonService.getSermonById(widget.initialSermonId!);
      if (sermon != null && mounted) {
        widget.audioPlayerService.playSermon(sermon);
      }
    } catch (e) {
      print('Error playing initial sermon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Sermons'),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/sermon_hero.jpg',
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search sermons...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty ||
                                      _selectedCategory != null ||
                                      _selectedPreacher != null ||
                                      _selectedTag != null
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearFilters,
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Banner ad between search bar and filter section
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: BannerAdWidget(adSize: AdSize.banner),
                          ),
                          const SizedBox(height: 16),
                          
                          // Filter Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filter By:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedCategory != null ||
                                  _selectedPreacher != null ||
                                  _selectedTag != null)
                                TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Clear All'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: Text(
                                      'Preacher: ${_selectedPreacher ?? 'All'}'),
                                  selected: _selectedPreacher != null,
                                  onSelected: (_) async {
                                    final preacher = await showDialog<String>(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        title: const Text('Select Preacher'),
                                        children: [
                                          SimpleDialogOption(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            child: const Text('All'),
                                          ),
                                          ..._preachers.map(
                                              (preacher) => SimpleDialogOption(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, preacher),
                                                    child: Text(preacher),
                                                  )),
                                        ],
                                      ),
                                    );
                                    setState(() {
                                      _selectedPreacher = preacher;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text(
                                      'Category: ${_selectedCategory ?? 'All'}'),
                                  selected: _selectedCategory != null,
                                  onSelected: (_) async {
                                    final category = await showDialog<String>(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        title: const Text('Select Category'),
                                        children: [
                                          SimpleDialogOption(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            child: const Text('All'),
                                          ),
                                          ..._categories.map(
                                              (category) => SimpleDialogOption(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, category),
                                                    child: Text(category),
                                                  )),
                                        ],
                                      ),
                                    );
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text('Tags: ${_selectedTag ?? 'All'}'),
                                  selected: _selectedTag != null,
                                  onSelected: (_) async {
                                    final tag = await showDialog<String>(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        title: const Text('Select Tag'),
                                        children: [
                                          SimpleDialogOption(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            child: const Text('All'),
                                          ),
                                          ..._tags.map((tag) =>
                                              SimpleDialogOption(
                                                onPressed: () =>
                                                    Navigator.pop(context, tag),
                                                child: Text(tag),
                                              )),
                                        ],
                                      ),
                                    );
                                    setState(() {
                                      _selectedTag = tag;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Bookmarked'),
                        Tab(text: 'Downloaded'),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // All Sermons Tab
                  _buildSermonList(null),
                  // Bookmarked Sermons Tab
                  _buildSermonList('bookmarked'),
                  // Downloaded Sermons Tab
                  _buildSermonList('downloaded'),
                ],
              ),
            ),
          ),
          if (_showMiniPlayer && _currentSermon != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                sermon: _currentSermon!,
                audioPlayerService: widget.audioPlayerService,
                onClose: _closeMiniPlayer,
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSermonList(String? filter) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<Sermon>>(
        future: widget.sermonService.getSermons(
          category: _selectedCategory,
          preacher: _selectedPreacher,
          tags: _selectedTag != null ? [_selectedTag!] : null,
          searchQuery: _searchQuery,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var sermons = snapshot.data!;

          // Apply tab-specific filters
          if (filter == 'bookmarked') {
            sermons = sermons.where((sermon) => sermon.isBookmarked).toList();
          } else if (filter == 'downloaded') {
            sermons = sermons.where((sermon) => sermon.isDownloaded).toList();
          }

          // Apply search and other filters
          final filteredSermons = sermons.where((sermon) {
            final matchesSearch = _searchQuery.isEmpty ||
                sermon.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                sermon.preacherName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

            final matchesPreacher = _selectedPreacher == null ||
                sermon.preacherName == _selectedPreacher;

            final matchesCategory = _selectedCategory == null ||
                sermon.category == _selectedCategory;

            final matchesTag =
                _selectedTag == null || sermon.tags.contains(_selectedTag);

            return matchesSearch &&
                matchesPreacher &&
                matchesCategory &&
                matchesTag;
          }).toList();

          if (filteredSermons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No sermons found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              bottom: _showMiniPlayer ? 100 : 16,
            ),
            itemCount: filteredSermons.length + (filteredSermons.length ~/ 4), // Add extra items for ads
            itemBuilder: (context, index) {
              // Calculate the actual sermon index accounting for ad positions
              final int adCount = index ~/ 5; // Every 5th item (after 4 sermons) is an ad
              final int sermonIndex = index - adCount;
              
              // Check if this position should display an ad
              if (index > 0 && index % 5 == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: BannerAdWidget(adSize: AdSize.mediumRectangle),
                );
              }
              
              // If we've reached the end of our sermon list, don't try to display a sermon
              if (sermonIndex >= filteredSermons.length) {
                return const SizedBox.shrink();
              }
              
              final sermon = filteredSermons[sermonIndex];
              return SermonCard(
                sermon: sermon,
                audioPlayerService: widget.audioPlayerService,
                sermonService: widget.sermonService,
                onTap: () => _playSermon(sermon, filteredSermons),
                onRefresh: () {
                  // Refresh the sermon list to get updated counter values
                  setState(() {
                    _isLoading = true;
                  });
                  _initializeData();
                },
              );
            },
          );
        },
      ),
    );
  }
}

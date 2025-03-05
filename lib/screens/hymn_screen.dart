import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hymn_detail_screen.dart';

class Hymn {
  Hymn({
    required this.hymnNumber,
    required this.title,
    required this.author,
    required this.lyrics,
    this.chorus,
    this.isBookmarked = false,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      hymnNumber: json['hymn_number'],
      title: json['title'],
      author: json['author'],
      lyrics: (json['lyrics'] as List<dynamic>)
          .map((stanza) =>
              (stanza as List<dynamic>).map((line) => line.toString()).toList())
          .toList(),
      chorus: json['chorus'] != null
          ? (json['chorus'] as List<dynamic>)
              .map((line) => line.toString())
              .toList()
          : null,
    );
  }
  final int hymnNumber;
  final String title;
  final String author;
  final List<List<String>> lyrics;
  final List<String>? chorus;
  bool isBookmarked;

  Map<String, dynamic> toJson() => {
        'hymn_number': hymnNumber,
        'title': title,
        'author': author,
        'lyrics': lyrics,
        'chorus': chorus,
        'isBookmarked': isBookmarked,
      };
}

class HymnScreen extends StatefulWidget {
  const HymnScreen({Key? key}) : super(key: key);

  @override
  _HymnScreenState createState() => _HymnScreenState();
}

class _HymnScreenState extends State<HymnScreen>
    with SingleTickerProviderStateMixin {
  List<Hymn> _allHymns = [];
  List<Hymn> _hymns = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  late TabController _tabController;
  Set<int> _bookmarkedHymns = {};

  List<Hymn> _getFilteredHymns() {
    final query = _searchController.text.toLowerCase();
    final List<Hymn> filteredBySearch = query.isEmpty
        ? _allHymns
        : _allHymns.where((hymn) {
            final numberMatch = hymn.hymnNumber.toString().contains(query);
            final titleMatch = hymn.title.toLowerCase().contains(query);
            return numberMatch || titleMatch;
          }).toList();

    return _tabController.index == 0
        ? filteredBySearch
        : filteredBySearch.where((hymn) => hymn.isBookmarked).toList();
  }

  void _filterHymns(String query) {
    setState(() {
      _hymns = _getFilteredHymns();
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _hymns = _getFilteredHymns();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _loadHymns();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_hymns') ?? [];
    setState(() {
      _bookmarkedHymns = bookmarks.map((s) => int.parse(s)).toSet();
      for (var hymn in _allHymns) {
        hymn.isBookmarked = _bookmarkedHymns.contains(hymn.hymnNumber);
      }
    });
  }

  Future<void> _loadHymns() async {
    try {
      final String response =
          await rootBundle.loadString('assets/docs/hymns.json');
      final List<dynamic> hymnsJson = json.decode(response);
      setState(() {
        _allHymns = hymnsJson.map((json) => Hymn.fromJson(json)).toList();
        _hymns = _allHymns;
        _isLoading = false;
      });
      await _loadBookmarks();
    } catch (e) {
      print('Error loading hymns: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Hymnal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/hymnal_header.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 120.0,
              maxHeight: 120.0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                      child: TextFormField(
                        controller: _searchController,
                        onChanged: _filterHymns,
                        decoration: InputDecoration(
                          hintText: 'Search by hymn number or title',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          filled: true,
                          fillColor: Colors.grey[100],
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.search,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TabBar(
                        controller: _tabController,
                        onTap: _onTabChanged,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(
                            child: Text(
                              'All Hymns',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Tab(
                            child: Text(
                              'Bookmarked',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHymnList(_hymns),
            _buildHymnList(_hymns.where((hymn) => hymn.isBookmarked).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHymnList(List<Hymn> hymns) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hymns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _tabController.index == 0
                ? 'No hymns found'
                : 'No bookmarked hymns',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: hymns.length,
      itemBuilder: (context, index) {
        final hymn = hymns[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(
              hymn.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Hymn #${hymn.hymnNumber}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
            trailing: Icon(
              hymn.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => _openHymnDetail(hymn),
          ),
        );
      },
    );
  }

  Future<void> _openHymnDetail(Hymn hymn) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HymnDetailScreen(
          hymn: hymn,
          onBookmarkChanged: (isBookmarked) {
            setState(() {
              hymn.isBookmarked = isBookmarked;
              if (isBookmarked) {
                _bookmarkedHymns.add(hymn.hymnNumber);
              } else {
                _bookmarkedHymns.remove(hymn.hymnNumber);
              }
              _saveBookmarks();
            });
          },
        ),
      ),
    );

    if (result == true) {
      _filterHymns(_searchController.text);
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = _bookmarkedHymns.map((id) => id.toString()).toList();
    await prefs.setStringList('bookmarked_hymns', bookmarks);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

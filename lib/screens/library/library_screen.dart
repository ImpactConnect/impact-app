import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../screens/library/book_detail_screen.dart';
import '../../services/ad_service.dart';
import '../../services/book_service.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/library/book_card.dart';
import '../../widgets/library/book_grid.dart';
import '../../widgets/library/filter_section.dart';
import '../../widgets/library/library_hero.dart';
import '../../widgets/library/search_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  final AdService _adService = AdService();
  late TabController _tabController;
  String? _searchQuery;
  String? _selectedCategory;
  String? _selectedAuthor;
  List<String>? _selectedTopics;
  final ScrollController _scrollController = ScrollController();
  bool _showPremiumContent = false;

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedAuthor != null ||
      (_selectedTopics?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Book>> _getBookmarkedBooks() async {
    final bookmarkedBooks = await _bookService.getBookmarkedBooks();
    return bookmarkedBooks;
  }

  Future<List<Book>> _getDownloadedBooks() async {
    final downloadedBooks = await _bookService.getDownloadedBooks();
    return downloadedBooks;
  }

  Widget _buildBookSection(
      String title, Future<List<Book>> Function() getBooks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to see all books in this category
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // Increased height to accommodate book covers
          child: FutureBuilder<List<Book>>(
            future: getBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No books available'));
              }

              final books = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  // Using a custom card layout for horizontal scrolling
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(book: book),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Book cover image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: book.coverUrl.isNotEmpty
                                    ? Image.network(
                                        book.coverUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.image_not_supported, size: 40),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(Icons.book, size: 40),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Book title
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Book author
                          Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              const SliverToBoxAdapter(child: LibraryHero()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LibrarySearchBar(
                    onSearch: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildBookSection('Trending Books',
                        () => _bookService.getTrendingBooks()),
                    // Banner ad after book list
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: BannerAdWidget(adSize: AdSize.banner),
                    ),
                    _buildBookSection('Recommended',
                        () => _bookService.getRecommendedBooks()),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  Material(
                    elevation: 2,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SizedBox(
                      width: double.infinity,
                      height: 130, // Fixed container height
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 48, // Fixed tab bar height
                            child: TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'All Books'),
                                Tab(text: 'Bookmarked'),
                                Tab(text: 'Downloaded'),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 82, // Remaining space for filter section
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 2),
                                  child: Text(
                                    'Browse Books by:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FilterSection(
                                    selectedCategory: _selectedCategory,
                                    selectedAuthor: _selectedAuthor,
                                    selectedTopics: _selectedTopics,
                                    onCategorySelected: (category) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                    onAuthorSelected: (author) {
                                      setState(() {
                                        _selectedAuthor = author;
                                      });
                                    },
                                    onTopicsSelected: (topics) {
                                      setState(() {
                                        _selectedTopics = topics;
                                      });
                                    },
                                    onClearFilters: () {
                                      setState(() {
                                        _selectedCategory = null;
                                        _selectedAuthor = null;
                                        _selectedTopics = null;
                                      });
                                    },
                                    hasActiveFilters: _hasActiveFilters,
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
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              FutureBuilder<List<Book>>(
                future: _bookService.getBooks(
                  searchQuery: _searchQuery,
                  category: _selectedCategory,
                  author: _selectedAuthor,
                  topics: _selectedTopics,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No books found'));
                  }
                  return BookGrid(books: snapshot.data!);
                },
              ),
              FutureBuilder<List<Book>>(
                future: _getBookmarkedBooks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No bookmarked books'));
                  }
                  return BookGrid(books: snapshot.data!);
                },
              ),
              FutureBuilder<List<Book>>(
                future: _getDownloadedBooks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No downloaded books'));
                  }
                  return BookGrid(books: snapshot.data!);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.child);
  final Widget child;

  @override
  double get minExtent => 130;

  @override
  double get maxExtent => 130;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}

import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/library/book_card.dart';
import '../../widgets/library/book_grid.dart';
import '../../widgets/library/filter_section.dart';
import '../../widgets/library/library_hero.dart';
import '../../widgets/library/search_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  late TabController _tabController;
  String? _searchQuery;
  String? _selectedCategory;
  String? _selectedAuthor;
  List<String>? _selectedTopics;
  final ScrollController _scrollController = ScrollController();

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
    return FutureBuilder<List<Book>>(
      future: getBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 160,
                      child: BookCard(book: snapshot.data![index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Library'),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      //   elevation: 0,
      //   backgroundColor: Colors.transparent,
      // ),
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
                    _buildBookSection('Most Downloaded',
                        () => _bookService.getMostDownloadedBooks()),
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

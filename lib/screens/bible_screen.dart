import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';
import 'book_chapter_selection_screen.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({
    super.key,
    required this.bibleService,
    this.initialBook,
    this.initialChapter,
  });
  final BibleService? bibleService;
  final Book? initialBook;
  final Chapter? initialChapter;

  @override
  _BibleScreenState createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen>
    with SingleTickerProviderStateMixin {
  BibleService? get _bibleService => widget.bibleService;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<Book> _searchResults = [];
  List<Book> _allBooks = [];
  Book? _currentBook;
  Chapter? _currentChapter;
  bool _isSearching = false;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBible();
  }

  Future<void> _loadBible() async {
    try {
      await _bibleService?.loadBible();
      if (mounted) {
        setState(() {
          _allBooks = _bibleService?.getAllBooks() ?? [];

          // Set initial book and chapter if provided
          if (widget.initialBook != null) {
            _currentBook = _allBooks.firstWhere(
                (book) => book.name == widget.initialBook!.name,
                orElse: () => _allBooks.first);
          } else if (_allBooks.isNotEmpty) {
            _currentBook = _allBooks.first;
          }

          // Set initial chapter if provided or use first chapter of current book
          if (widget.initialChapter != null) {
            _currentChapter = _currentBook?.chapters.firstWhere(
                (chapter) => chapter.number == widget.initialChapter!.number,
                orElse: () => _currentBook!.chapters.first);
          } else if (_currentBook != null) {
            _currentChapter = _currentBook!.chapters.first;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Bible: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading Bible: $e')),
        );
      }
    }
  }

  void _showVerseOptions(Verse verse, String bookName, int chapterNumber) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              verse.getReference(bookName, chapterNumber),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(verse.text),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.copy,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          '${verse.getReference(bookName, chapterNumber)}: ${verse.text}',
                    ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Verse copied to clipboard')),
                    );
                  },
                ),
                _buildOptionButton(
                  icon: verse.isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: 'Bookmark',
                  onTap: () {
                    _toggleBookmark(verse);
                    Navigator.pop(context);
                  },
                ),
                _buildOptionButton(
                  icon: verse.isHighlighted
                      ? Icons.highlight
                      : Icons.highlight_alt,
                  label: 'Highlight',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleHighlight(verse);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    _shareVerse(verse, bookName, chapterNumber);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            if (verse.note != null) ...[
              const SizedBox(height: 16),
              Text(
                'Note: ${verse.note}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.note_add),
              label: Text(verse.note == null ? 'Add Note' : 'Edit Note'),
              onPressed: () {
                Navigator.pop(context);
                _addNote(verse);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showBookSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookChapterSelectionScreen(
          bibleService: _bibleService,
          books: _allBooks,
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (_bibleService == null) return;
    setState(() {
      _searchResults = _bibleService!.searchBible(query);
      _isSearching = query.isNotEmpty;
    });
  }

  void _shareVerse(Verse verse, String bookName, int chapterNumber) {
    final reference = verse.getReference(bookName, chapterNumber);
    Share.share('$reference: ${verse.text}');
  }

  Future<void> _toggleBookmark(Verse verse) async {
    if (_bibleService == null) return;
    setState(() {
      verse.toggleBookmark();
    });
    await _bibleService!.savePreferences();
  }

  Future<void> _toggleHighlight(Verse verse) async {
    if (_bibleService == null) return;
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose highlight color'),
        children: [
          _buildColorOption(Colors.yellow[200]!, 'Yellow'),
          _buildColorOption(Colors.green[200]!, 'Green'),
          _buildColorOption(Colors.blue[200]!, 'Blue'),
          _buildColorOption(Colors.pink[200]!, 'Pink'),
        ],
      ),
    );

    if (color != null) {
      setState(() {
        verse.toggleHighlight(color);
      });
      await _bibleService!.savePreferences();
    }
  }

  Widget _buildColorOption(Color color, String label) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, color),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _addNote(Verse verse) async {
    if (_bibleService == null) return;
    _noteController.text = verse.note ?? '';
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _noteController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (note != null) {
      setState(() {
        verse.addNote(note);
      });
      await _bibleService!.savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Bible...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _performSearch,
              )
            : InkWell(
                onTap: _showBookSelection,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentBook?.name ?? 'Select Book',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (_currentChapter != null) ...[
                      const Text(' - '),
                      Text(
                        'Ch ${_currentChapter!.number}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _searchResults.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Bible'),
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.highlight), text: 'Highlights'),
            Tab(icon: Icon(Icons.note), text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isSearching ? _buildSearchResults() : _buildVerseList(),
          _buildBookmarkedVerses(),
          _buildHighlightedVerses(),
          _buildVersesWithNotes(),
        ],
      ),
    );
  }

  Widget _buildVerseList() {
    if (_currentBook == null || _currentChapter == null) {
      return const Center(child: Text('Select a book and chapter'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _currentChapter!.verses.length,
            itemBuilder: (context, index) {
              final verse = _currentChapter!.verses[index];
              return InkWell(
                onTap: () => _showVerseOptions(
                  verse,
                  _currentBook!.name,
                  _currentChapter!.number,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: verse.isHighlighted
                      ? verse.highlightColor?.withOpacity(0.3)
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${verse.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(verse.text),
                      ),
                      if (verse.isBookmarked || verse.note != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (verse.isBookmarked)
                              const Icon(Icons.bookmark,
                                  size: 16, color: Colors.grey),
                            if (verse.note != null)
                              const Icon(Icons.note,
                                  size: 16, color: Colors.grey),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                onPressed: () {
                  if (_bibleService == null) return;
                  final prevChapter = _bibleService!.getPreviousChapter(
                    _currentBook!,
                    _currentChapter!.number,
                  );
                  if (prevChapter != null) {
                    setState(() {
                      _currentBook = prevChapter;
                      _currentChapter = prevChapter.chapters.first;
                    });
                  }
                },
              ),
              Text(
                '${_currentBook!.name} ${_currentChapter!.number}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                onPressed: () {
                  if (_bibleService == null) return;
                  final nextChapter = _bibleService!.getNextChapter(
                    _currentBook!,
                    _currentChapter!.number,
                  );
                  if (nextChapter != null) {
                    setState(() {
                      _currentBook = nextChapter;
                      _currentChapter = nextChapter.chapters.first;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(child: Text('Enter text to search'));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, bookIndex) {
        final book = _searchResults[bookIndex];
        return ExpansionTile(
          title: Text(book.name),
          initiallyExpanded: true,
          children: book.chapters.expand((chapter) {
            return chapter.verses.map((verse) {
              final verseText = verse.text;
              final searchQuery = _searchController.text.toLowerCase();
              final textSpans = <TextSpan>[];

              // Highlight matching text
              int lastMatchEnd = 0;
              final matches = searchQuery.allMatches(verseText.toLowerCase());

              for (final match in matches) {
                if (match.start > lastMatchEnd) {
                  textSpans.add(TextSpan(
                    text: verseText.substring(lastMatchEnd, match.start),
                  ));
                }

                textSpans.add(TextSpan(
                  text: verseText.substring(match.start, match.end),
                  style: const TextStyle(
                    backgroundColor: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ));

                lastMatchEnd = match.end;
              }

              if (lastMatchEnd < verseText.length) {
                textSpans.add(TextSpan(
                  text: verseText.substring(lastMatchEnd),
                ));
              }

              return InkWell(
                onTap: () =>
                    _showVerseOptions(verse, book.name, chapter.number),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.getReference(book.name, chapter.number),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: textSpans,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookmarkedVerses() {
    if (_bibleService == null) {
      return const Center(child: Text('Bible service not initialized'));
    }

    final bookmarkedVerses = _bibleService!.getBookmarkedVerses();
    if (bookmarkedVerses.isEmpty) {
      return const Center(child: Text('No bookmarked verses'));
    }

    return ListView.builder(
      itemCount: bookmarkedVerses.length,
      itemBuilder: (context, index) {
        final verse = bookmarkedVerses[index];
        // TODO: Get proper book name and chapter number
        return InkWell(
          onTap: () => _showVerseOptions(verse, '', 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.getReference('', 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(verse.text),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightedVerses() {
    if (_bibleService == null) {
      return const Center(child: Text('Bible service not initialized'));
    }

    final highlightedVerses = _bibleService!.getHighlightedVerses();
    if (highlightedVerses.isEmpty) {
      return const Center(child: Text('No highlighted verses'));
    }

    return ListView.builder(
      itemCount: highlightedVerses.length,
      itemBuilder: (context, index) {
        final verse = highlightedVerses[index];
        // TODO: Get proper book name and chapter number
        return InkWell(
          onTap: () => _showVerseOptions(verse, '', 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: verse.highlightColor?.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.getReference('', 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(verse.text),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersesWithNotes() {
    if (_bibleService == null) {
      return const Center(child: Text('Bible service not initialized'));
    }

    final versesWithNotes = _bibleService!.getVersesWithNotes();
    if (versesWithNotes.isEmpty) {
      return const Center(child: Text('No verses with notes'));
    }

    return ListView.builder(
      itemCount: versesWithNotes.length,
      itemBuilder: (context, index) {
        final verse = versesWithNotes[index];
        // TODO: Get proper book name and chapter number
        return InkWell(
          onTap: () => _showVerseOptions(verse, '', 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.getReference('', 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(verse.text),
                if (verse.note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${verse.note}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

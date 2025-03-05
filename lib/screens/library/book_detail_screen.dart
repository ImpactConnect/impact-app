import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({
    Key? key,
    required this.book,
  }) : super(key: key);
  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  bool _isBookmarked = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _loadBookStatus();
  }

  Future<void> _loadBookStatus() async {
    final bookmarkedBooks = await _bookService.getBookmarkedBooks();
    final downloadedBooks = await _bookService.getDownloadedBooks();

    setState(() {
      _isBookmarked = bookmarkedBooks.contains(widget.book.id);
      _isDownloaded = downloadedBooks.contains(widget.book.id);
    });
  }

  Future<void> _toggleBookmark() async {
    await _bookService.toggleBookmark(widget.book.id);
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _downloadBook() async {
    // Show download progress indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading book...')),
    );

    // TODO: Implement actual download logic here
    await Future.delayed(const Duration(seconds: 2)); // Simulated download
    await _bookService.markAsDownloaded(widget.book.id);

    setState(() => _isDownloaded = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book downloaded successfully')),
      );
    }
  }

  void _shareBook() {
    Share.share(
      'Check out this book: ${widget.book.title} by ${widget.book.author}',
      subject: widget.book.title,
    );
  }

  void _openReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfReaderScreen(book: widget.book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'book-${widget.book.id}',
                child: Image.network(
                  widget.book.coverUrl,
                  fit: BoxFit.cover,
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
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${widget.book.author}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.book.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: widget.book.topics.map((topic) {
                      return Chip(label: Text(topic));
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isBookmarked
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                      IconButton(
                        icon: Icon(
                          _isDownloaded ? Icons.download_done : Icons.download,
                          color: _isDownloaded
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        onPressed: _isDownloaded ? null : _downloadBook,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _shareBook,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openReader,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Read Now'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

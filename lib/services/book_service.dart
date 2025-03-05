import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookmarksKey = 'bookmarked_books';
  final String _downloadedBooksKey = 'downloaded_books';
  final String _readingProgressKey = 'reading_progress';

  // Fetch books with optional filters
  Future<List<Book>> getBooks({
    String? searchQuery,
    String? category,
    String? author,
    List<String>? topics,
  }) async {
    Query query =
        _firestore.collection('books').where('isActive', isEqualTo: true);

    // Apply filters
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (author != null) {
      query = query.where('author', isEqualTo: author);
    }
    if (topics != null && topics.isNotEmpty) {
      query = query.where('topics', arrayContainsAny: topics);
    }

    // Get results
    final snapshot = await query.get();
    var books = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();

    // Apply search filter in memory if search query exists
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      books = books.where((book) {
        return book.title.toLowerCase().contains(searchLower) ||
            book.author.toLowerCase().contains(searchLower) ||
            book.description.toLowerCase().contains(searchLower) ||
            book.category.toLowerCase().contains(searchLower) ||
            book.topics
                .any((topic) => topic.toLowerCase().contains(searchLower));
      }).toList();
    }

    return books;
  }

  // Get trending books (admin controlled)
  Future<List<Book>> getTrendingBooks() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .where('isTrending', isEqualTo: true)
          .orderBy('trendingOrder')
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting trending books: $e');
      return [];
    }
  }

  // Get most read books (admin controlled)
  Future<List<Book>> getMostReadBooks() async {
    final snapshot = await _firestore
        .collection('books')
        .where('isMostRead', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('mostReadOrder')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  // Get most downloaded books (admin controlled)
  Future<List<Book>> getMostDownloadedBooks() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .where('isMostDownloaded', isEqualTo: true)
          .orderBy('mostDownloadedOrder')
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting most downloaded books: $e');
      return [];
    }
  }

  // Get recommended books (admin controlled)
  Future<List<Book>> getRecommendedBooks() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .where('isRecommended', isEqualTo: true)
          .orderBy('recommendedOrder')
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting recommended books: $e');
      return [];
    }
  }

  // Get all books
  Future<List<Book>> getAllBooks() async {
    final snapshot = await _firestore
        .collection('books')
        .where('isActive', isEqualTo: true)
        .orderBy('publishedDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  // Get bookmarked books
  Future<List<Book>> getBookmarkedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkIds = prefs.getStringList(_bookmarksKey) ?? [];

    if (bookmarkIds.isEmpty) return [];

    final snapshot = await _firestore
        .collection('books')
        .where(FieldPath.documentId, whereIn: bookmarkIds)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  // Get downloaded books
  Future<List<Book>> getDownloadedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedIds = prefs.getStringList(_downloadedBooksKey) ?? [];

    if (downloadedIds.isEmpty) return [];

    final snapshot = await _firestore
        .collection('books')
        .where(FieldPath.documentId, whereIn: downloadedIds)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  }

  // Toggle bookmark
  Future<void> toggleBookmark(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarksKey) ?? [];

    if (bookmarks.contains(bookId)) {
      bookmarks.remove(bookId);
    } else {
      bookmarks.add(bookId);
    }

    await prefs.setStringList(_bookmarksKey, bookmarks);
  }

  // Mark book as downloaded
  Future<void> markAsDownloaded(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedBooks = prefs.getStringList(_downloadedBooksKey) ?? [];

    if (!downloadedBooks.contains(bookId)) {
      downloadedBooks.add(bookId);
      await prefs.setStringList(_downloadedBooksKey, downloadedBooks);
    }
  }

  // Update reading progress
  Future<void> updateReadingProgress(String bookId, int currentPage) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getStringList(_readingProgressKey) ?? [];
    final progressEntry = '$bookId:$currentPage';

    // Remove old progress for this book
    progress.removeWhere((entry) => entry.startsWith('$bookId:'));
    progress.add(progressEntry);

    await prefs.setStringList(_readingProgressKey, progress);
  }

  // Get reading progress
  Future<Map<String, int>> getReadingProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getStringList(_readingProgressKey) ?? [];
    final entry = progress.firstWhere(
      (entry) => entry.startsWith('$bookId:'),
      orElse: () => '$bookId:1',
    );

    final currentPage = int.tryParse(entry.split(':')[1]) ?? 1;
    return {'currentPage': currentPage};
  }

  Future<List<String>> getAuthors() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['author'] as String)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort alphabetically
    } catch (e) {
      print('Error getting authors: $e');
      return [];
    }
  }

  Future<List<String>> getTopics() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .get();

      final Set<String> topics = {};
      for (var doc in querySnapshot.docs) {
        final bookTopics = List<String>.from(doc.data()['topics'] ?? []);
        topics.addAll(bookTopics);
      }

      return topics.toList()..sort();
    } catch (e) {
      print('Error getting topics: $e');
      return [];
    }
  }
}

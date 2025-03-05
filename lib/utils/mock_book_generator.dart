import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class MockBookGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateMockBooks() async {
    // Clear existing books
    await _clearExistingBooks();

    // Sample book data
    final List<Book> mockBooks = [
      Book(
        id: 'book1',
        title: 'Understanding Grace',
        author: 'John Smith',
        category: 'Theology',
        topics: ['Grace', 'Salvation', 'Faith'],
        coverUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
        pdfUrl: 'https://example.com/books/understanding-grace.pdf',
        description: 'A comprehensive study on the doctrine of grace in Christianity.',
        publishedDate: DateTime(2024, 1, 15),
        totalPages: 250,
        isTrending: true,
        trendingOrder: 1,
      ),
      Book(
        id: 'book2',
        title: 'Prayer Warriors',
        author: 'Sarah Johnson',
        category: 'Christian Living',
        topics: ['Prayer', 'Spiritual Warfare', 'Faith'],
        coverUrl: 'https://images.unsplash.com/photo-1532012197267-da84d127e765',
        pdfUrl: 'https://example.com/books/prayer-warriors.pdf',
        description: 'Learn the power of prayer and spiritual warfare.',
        publishedDate: DateTime(2024, 2, 1),
        totalPages: 180,
        isMostRead: true,
        mostReadOrder: 1,
      ),
      Book(
        id: 'book3',
        title: 'Walking with Christ',
        author: 'David Wilson',
        category: 'Christian Living',
        topics: ['Discipleship', 'Faith', 'Christian Life'],
        coverUrl: 'https://images.unsplash.com/photo-1476275466078-4007374efbbe',
        pdfUrl: 'https://example.com/books/walking-with-christ.pdf',
        description: 'A guide to daily Christian living and discipleship.',
        publishedDate: DateTime(2024, 1, 20),
        totalPages: 200,
        isRecommended: true,
        recommendedOrder: 1,
      ),
      Book(
        id: 'book4',
        title: 'Bible Study Methods',
        author: 'Michael Brown',
        category: 'Bible Study',
        topics: ['Bible', 'Study', 'Methods'],
        coverUrl: 'https://images.unsplash.com/photo-1519682577862-22b62b24e493',
        pdfUrl: 'https://example.com/books/bible-study-methods.pdf',
        description: 'Learn effective methods for studying the Bible.',
        publishedDate: DateTime(2024, 1, 25),
        totalPages: 150,
        isTrending: true,
        trendingOrder: 2,
      ),
      Book(
        id: 'book5',
        title: 'The Power of Worship',
        author: 'Emily Davis',
        category: 'Ministry',
        topics: ['Worship', 'Music', 'Church'],
        coverUrl: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76',
        pdfUrl: 'https://example.com/books/power-of-worship.pdf',
        description: 'Understanding the importance of worship in Christian life.',
        publishedDate: DateTime(2024, 2, 5),
        totalPages: 160,
        isMostRead: true,
        mostReadOrder: 2,
      ),
    ];

    // Add books to Firestore
    for (final book in mockBooks) {
      await _firestore.collection('books').doc(book.id).set(book.toFirestore());
    }
  }

  Future<void> _clearExistingBooks() async {
    final snapshot = await _firestore.collection('books').get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

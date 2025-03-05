import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.topics,
    required this.coverUrl,
    required this.pdfUrl,
    required this.description,
    required this.publishedDate,
    required this.totalPages,
    this.isTrending = false,
    this.isMostRead = false,
    this.isRecommended = false,
    this.trendingOrder = 0,
    this.mostReadOrder = 0,
    this.recommendedOrder = 0,
    this.isActive = true,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      coverUrl: data['coverUrl'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      description: data['description'] ?? '',
      publishedDate: (data['publishedDate'] as Timestamp).toDate(),
      totalPages: data['totalPages'] ?? 0,
      isTrending: data['isTrending'] ?? false,
      isMostRead: data['isMostRead'] ?? false,
      isRecommended: data['isRecommended'] ?? false,
      trendingOrder: data['trendingOrder'] ?? 0,
      mostReadOrder: data['mostReadOrder'] ?? 0,
      recommendedOrder: data['recommendedOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
  final String id;
  final String title;
  final String author;
  final String category;
  final List<String> topics;
  final String coverUrl;
  final String pdfUrl;
  final String description;
  final DateTime publishedDate;
  final int totalPages;

  // Admin control fields
  final bool isTrending;
  final bool isMostRead;
  final bool isRecommended;
  final int trendingOrder;
  final int mostReadOrder;
  final int recommendedOrder;
  final bool isActive;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'topics': topics,
      'coverUrl': coverUrl,
      'pdfUrl': pdfUrl,
      'description': description,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'totalPages': totalPages,
      'isTrending': isTrending,
      'isMostRead': isMostRead,
      'isRecommended': isRecommended,
      'trendingOrder': trendingOrder,
      'mostReadOrder': mostReadOrder,
      'recommendedOrder': recommendedOrder,
      'isActive': isActive,
    };
  }
}

import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../screens/library/book_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BookGrid extends StatelessWidget {
  const BookGrid({
    Key? key,
    required this.books,
  }) : super(key: key);
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(child: Text('No books found'));
    }

    // Calculate total items including ads
    // Add 1 ad after every 6 books (3 rows of 2 books each)
    final int itemCount = books.length + (books.length ~/ 6);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Check if this position should be an ad
        // Ads are placed after every 6 books (at positions 6, 13, 20, etc.)
        if (index > 0 && index % 7 == 6) {
          // This is an ad position
          return GridSpan(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: BannerAdWidget(adSize: AdSize.banner),
            ),
          );
        }
        
        // Calculate the actual book index
        final int bookIndex = index - (index ~/ 7);
        final book = books[bookIndex];
        
        // Return improved book card
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
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
        );
      },
    );
  }
}

// Widget to make an item span the full width of the grid
class GridSpan extends StatelessWidget {
  final Widget child;
  
  const GridSpan({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 90,
      child: child,
    );
  }
}

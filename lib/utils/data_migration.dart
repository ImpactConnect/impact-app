import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataMigration {
  static const String _carouselMigrationKey = 'carousel_migration_completed_v1';

  static Future<void> migrateCarouselItems() async {
    // Check if migration has already been run
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_carouselMigrationKey) == true) {
      print('Carousel migration already completed');
      return;
    }

    try {
      final carouselRef =
          FirebaseFirestore.instance.collection('carousel_items');

      // Get all carousel items
      final snapshot = await carouselRef.get();

      // Update each item
      for (var doc in snapshot.docs) {
        final data = doc.data();
        String? itemType;

        // Determine item type based on linkUrl
        if (data['linkUrl'] != null) {
          final linkUrl = data['linkUrl'] as String;
          if (linkUrl.startsWith('/sermons')) {
            itemType = 'sermon';
          } else if (linkUrl.startsWith('/events')) {
            itemType = 'event';
          } else if (linkUrl.startsWith('/blog')) {
            itemType = 'blog';
          } else {
            itemType = 'other';
          }
        } else {
          itemType = 'other';
        }

        // Update the document with the new itemType field
        await doc.reference.update({
          'itemType': itemType,
        });
      }

      // Mark migration as completed
      await prefs.setBool(_carouselMigrationKey, true);
      print('Carousel migration completed successfully');
    } catch (e) {
      print('Error during carousel migration: $e');
      // Don't mark as completed if there was an error
      rethrow;
    }
  }
}

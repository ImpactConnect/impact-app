import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/devotional.dart';
import '../utils/toast_utils.dart';

class DevotionalService {
  DevotionalService() {
    _initPrefs();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'devotionals';
  final String _bookmarksKey = 'bookmarked_devotionals';
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Get bookmarked devotional IDs
  Set<String> _getBookmarkedIds() {
    return _prefs?.getStringList(_bookmarksKey)?.toSet() ?? {};
  }

  // Save bookmarked devotional IDs
  Future<void> _saveBookmarkedIds(Set<String> bookmarkedIds) async {
    await _initPrefs();
    await _prefs?.setStringList(_bookmarksKey, bookmarkedIds.toList());
  }

  // Check if a devotional is bookmarked
  bool isBookmarked(Devotional devotional) {
    return _getBookmarkedIds().contains(devotional.id);
  }

  // Add a devotional to bookmarks
  Future<void> addBookmark(Devotional devotional) async {
    final bookmarkedIds = _getBookmarkedIds();
    bookmarkedIds.add(devotional.id);
    await _saveBookmarkedIds(bookmarkedIds);
  }

  // Remove a devotional from bookmarks
  Future<void> removeBookmark(Devotional devotional) async {
    final bookmarkedIds = _getBookmarkedIds();
    bookmarkedIds.remove(devotional.id);
    await _saveBookmarkedIds(bookmarkedIds);
  }

  // Get all bookmarked devotionals
  Future<List<Devotional>> getBookmarkedDevotionals() async {
    await _initPrefs();
    final bookmarkedIds = _getBookmarkedIds();
    if (bookmarkedIds.isEmpty) return [];

    try {
      final snapshots = await Future.wait(
        bookmarkedIds
            .map((id) => _firestore.collection(_collection).doc(id).get()),
      );

      return snapshots
          .where((doc) => doc.exists)
          .map((doc) => Devotional.fromFirestore(doc))
          .toList()
        ..sort(
            (a, b) => b.date.compareTo(a.date)); // Sort by date, newest first
    } catch (e) {
      print('Error fetching bookmarked devotionals: $e');
      return [];
    }
  }

  // Get devotionals with optional filters
  Future<List<Devotional>> getDevotionals({
    DateTime? selectedDate,
    String? searchQuery,
  }) async {
    try {
      Query query =
          _firestore.collection(_collection).orderBy('date', descending: true);

      if (selectedDate != null) {
        final startOfDay =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        query = query
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay));
      }

      final QuerySnapshot snapshot = await query.get();
      List<Devotional> devotionals =
          snapshot.docs.map((doc) => Devotional.fromFirestore(doc)).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        devotionals = devotionals.where((devotional) {
          return devotional.topic.toLowerCase().contains(searchLower) ||
              devotional.content.toLowerCase().contains(searchLower) ||
              devotional.author.toLowerCase().contains(searchLower) ||
              devotional.bibleVerse.toLowerCase().contains(searchLower);
        }).toList();
      }

      return devotionals;
    } catch (e) {
      print('Error fetching devotionals: $e');
      ToastUtils.showErrorToast('Error loading devotionals');
      return [];
    }
  }

  // Get recent devotionals
  Future<List<Devotional>> getRecentDevotionals() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => Devotional.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching recent devotionals: $e');
      ToastUtils.showErrorToast('Error loading recent devotionals');
      return [];
    }
  }

  // Get devotional by ID
  Future<Devotional?> getDevotionalById(String id) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        ToastUtils.showErrorToast('Devotional not found');
        return null;
      }

      return Devotional.fromFirestore(doc);
    } catch (e) {
      print('Error fetching devotional: $e');
      ToastUtils.showErrorToast('Error loading devotional');
      return null;
    }
  }
}

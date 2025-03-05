import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon.dart';
import '../utils/toast_utils.dart';

class SermonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsKey = 'sermons';

  Future<void> _saveToPrefs(Sermon sermon) async {
    final prefs = await SharedPreferences.getInstance();
    final sermons = await _loadFromPrefs();

    // Update or add the sermon
    final index = sermons.indexWhere((s) => s.id == sermon.id);
    if (index != -1) {
      sermons[index] = sermon;
    } else {
      sermons.add(sermon);
    }

    // Save the updated list
    final serializedSermons =
        sermons.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_prefsKey, serializedSermons);
  }

  Future<List<Sermon>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final serializedSermons = prefs.getStringList(_prefsKey) ?? [];

    return serializedSermons
        .map((s) => Sermon.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<List<Sermon>> getSermons({
    String? category,
    String? preacher,
    List<String>? tags,
    String? searchQuery,
  }) async {
    try {
      final Query query = _firestore.collection('sermons');

      // Get all sermons and filter in memory to avoid index requirements
      final QuerySnapshot snapshot = await query.get();
      List<Sermon> sermons =
          snapshot.docs.map((doc) => Sermon.fromFirestore(doc)).toList();

      // Apply filters in memory
      if (category != null) {
        sermons =
            sermons.where((sermon) => sermon.category == category).toList();
      }

      if (preacher != null) {
        sermons =
            sermons.where((sermon) => sermon.preacherName == preacher).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        sermons = sermons
            .where((sermon) => sermon.tags.any((tag) => tags.contains(tag)))
            .toList();
      }

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        sermons = sermons.where((sermon) {
          return sermon.title.toLowerCase().contains(searchLower) ||
              sermon.preacherName.toLowerCase().contains(searchLower) ||
              sermon.category.toLowerCase().contains(searchLower) ||
              sermon.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        }).toList();
      }

      // Sort by date
      sermons.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

      // Merge with local data
      final localSermons = await _loadFromPrefs();
      for (var localSermon in localSermons) {
        final index = sermons.indexWhere((s) => s.id == localSermon.id);
        if (index != -1) {
          sermons[index] = Sermon(
            id: localSermon.id,
            title: sermons[index].title,
            preacherName: sermons[index].preacherName,
            category: sermons[index].category,
            tags: sermons[index].tags,
            thumbnailUrl: sermons[index].thumbnailUrl,
            audioUrl: sermons[index].audioUrl,
            dateCreated: sermons[index].dateCreated,
            isBookmarked: localSermon.isBookmarked,
            isDownloaded: localSermon.isDownloaded,
            localAudioPath: localSermon.localAudioPath,
          );
        }
      }

      return sermons;
    } catch (e) {
      print('Error fetching sermons: $e');
      ToastUtils.showErrorToast('Error loading sermons');

      // On error, try to return cached data
      final cachedSermons = await _loadFromPrefs();
      if (cachedSermons.isNotEmpty) {
        return cachedSermons;
      }
      // If no cached data, create some mock data
      return _createMockSermons();
    }
  }

  List<Sermon> _createMockSermons() {
    return [
      Sermon(
        id: 'mock1',
        title: 'Welcome to Our Church',
        preacherName: 'Pastor John Doe',
        category: 'Welcome',
        tags: ['welcome', 'introduction'],
        thumbnailUrl: 'https://example.com/thumbnail1.jpg',
        audioUrl: 'https://example.com/sermon1.mp3',
        dateCreated: DateTime.now(),
        clickCount: 15,
        downloadCount: 5,
      ),
    ];
  }

  Future<void> downloadSermon(Sermon sermon) async {
    try {
      ToastUtils.showToast('Download started for "${sermon.title}"');

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${sermon.id}.mp3';
      final file = File('${appDir.path}/$fileName');

      if (!file.existsSync()) {
        final response = await http.get(Uri.parse(sermon.audioUrl));
        await file.writeAsBytes(response.bodyBytes);
      }

      sermon.isDownloaded = true;
      sermon.localAudioPath = file.path;
      
      // Increment download counter
      sermon.downloadCount += 1;
      
      // Update Firestore
      await _updateSermonCounters(sermon);
      
      await _saveToPrefs(sermon);

      ToastUtils.showSuccessToast('Download completed for "${sermon.title}"');
    } catch (e) {
      print('Error downloading sermon: $e');
      ToastUtils.showErrorToast('Failed to download "${sermon.title}"');
      rethrow;
    }
  }

  Future<void> incrementClickCount(Sermon sermon) async {
    try {
      // Increment click counter
      sermon.clickCount += 1;
      
      // Update Firestore
      await _updateSermonCounters(sermon);
      
      // Save to local storage
      await _saveToPrefs(sermon);
    } catch (e) {
      print('Error incrementing click count: $e');
      // Don't show error toast to user as this is a background operation
    }
  }
  
  Future<void> _updateSermonCounters(Sermon sermon) async {
    try {
      await _firestore.collection('sermons').doc(sermon.id).update({
        'clickCount': sermon.clickCount,
        'downloadCount': sermon.downloadCount,
      });
    } catch (e) {
      print('Error updating sermon counters in Firestore: $e');
      // We don't rethrow here to prevent disrupting the user experience
    }
  }

  Future<void> deleteDownloadedSermon(Sermon sermon) async {
    try {
      if (sermon.localAudioPath != null) {
        final file = File(sermon.localAudioPath!);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      sermon.isDownloaded = false;
      sermon.localAudioPath = null;
      await _saveToPrefs(sermon);

      ToastUtils.showSuccessToast('Deleted "${sermon.title}" from downloads');
    } catch (e) {
      print('Error deleting downloaded sermon: $e');
      ToastUtils.showErrorToast('Failed to delete "${sermon.title}"');
      rethrow;
    }
  }

  Future<void> toggleBookmark(Sermon sermon) async {
    try {
      sermon.isBookmarked = !sermon.isBookmarked;
      await _saveToPrefs(sermon);

      ToastUtils.showSuccessToast(sermon.isBookmarked
          ? '"${sermon.title}" added to bookmarks'
          : '"${sermon.title}" removed from bookmarks');
    } catch (e) {
      print('Error toggling bookmark: $e');
      ToastUtils.showErrorToast(
          'Failed to ${sermon.isBookmarked ? 'bookmark' : 'unbookmark'} "${sermon.title}"');
      rethrow;
    }
  }

  Future<List<Sermon>> getDownloadedSermons() async {
    final sermons = await _loadFromPrefs();
    return sermons.where((sermon) => sermon.isDownloaded).toList();
  }

  Future<List<Sermon>> getBookmarkedSermons() async {
    final sermons = await _loadFromPrefs();
    return sermons.where((sermon) => sermon.isBookmarked).toList();
  }

  Future<Sermon?> getSermonById(String id) async {
    try {
      final doc = await _firestore.collection('sermons').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Sermon.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting sermon by ID: $e');
      return null;
    }
  }

  Future<List<Sermon>> getSermonsByCategory(String categoryId) async {
    final snapshot = await _firestore
        .collection('sermons')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('dateCreated', descending: true)
        .get();

    return snapshot.docs.map((doc) => Sermon.fromFirestore(doc)).toList();
  }

  Future<List<Sermon>> searchSermons(String query) async {
    // Normalize query
    final normalizedQuery = query.toLowerCase().trim();
    
    try {
      // Get all sermons and filter manually
      final snapshot = await _firestore
          .collection('sermons')
          .orderBy('dateCreated', descending: true)
          .get();
      
      // Filter sermons manually
      final List<Sermon> matchingSermons = [];
      
      for (final doc in snapshot.docs) {
        try {
          final sermon = Sermon.fromFirestore(doc);
          final title = sermon.title.toLowerCase();
          final preacherName = sermon.preacherName.toLowerCase();
          final category = sermon.category.toLowerCase();
          final hasTags = sermon.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
          
          if (title.contains(normalizedQuery) || 
              preacherName.contains(normalizedQuery) ||
              category.contains(normalizedQuery) ||
              hasTags) {
            matchingSermons.add(sermon);
          }
        } catch (e) {
          // Skip this sermon if there's an error
          print('Error processing sermon: $e');
        }
      }
      
      return matchingSermons;
    } catch (e) {
      print('Error searching sermons: $e');
      return [];
    }
  }
}

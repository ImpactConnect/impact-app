import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon.dart';
import '../utils/toast_utils.dart';
import 'ad_service.dart';

class SermonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsKey = 'sermons';
  final AdService _adService = AdService();

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

      // Merge with local data but preserve Firestore counter values
      final localSermons = await _loadFromPrefs();
      for (var localSermon in localSermons) {
        final index = sermons.indexWhere((s) => s.id == localSermon.id);
        if (index != -1) {
          // Keep the Firestore counter values, but use local values for other fields
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
            clickCount: sermons[index].clickCount,  // Keep Firestore value
            downloadCount: sermons[index].downloadCount,  // Keep Firestore value
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
      print('Starting sermon download process for: ${sermon.title}');
      
      // Show download started toast
      ToastUtils.showSuccessToast('Download started for "${sermon.title}"');
      
      // Show an interstitial ad before downloading
      print('Attempting to show interstitial ad before download');
      bool adShown = false;
      try {
        if (!kIsWeb) {
          adShown = await _adService.showInterstitialAd();
          print('Interstitial ad shown: $adShown');
        }
      } catch (adError) {
        print('Error showing interstitial ad: $adError');
        // Continue with download even if ad fails
      }
      
      // Skip actual download on web platform
      if (kIsWeb) {
        // Simulate download for web
        await Future.delayed(const Duration(seconds: 2));
        sermon.isDownloaded = true;
        sermon.localAudioPath = 'simulated_path';
        await _saveToPrefs(sermon);
        ToastUtils.showSuccessToast('Downloaded "${sermon.title}"');
        print('Simulated download for web platform: ${sermon.title}');
        return;
      }
      
      // Get the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${sermon.id}.mp3';
      final filePath = '${appDir.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (file.existsSync()) {
        sermon.isDownloaded = true;
        sermon.localAudioPath = filePath;
        await _saveToPrefs(sermon);
        ToastUtils.showSuccessToast('Sermon already downloaded');
        print('Sermon already downloaded: ${sermon.title}');
        return;
      }

      print('Downloading sermon file from: ${sermon.audioUrl}');
      // Download the file
      final response = await http.get(Uri.parse(sermon.audioUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download sermon: HTTP ${response.statusCode}');
      }

      // Write the file
      await file.writeAsBytes(response.bodyBytes);
      print('Sermon file downloaded and saved to: $filePath');

      // Update sermon data
      sermon.isDownloaded = true;
      sermon.localAudioPath = filePath;
      sermon.downloadCount++;

      // Save to local storage and update counters
      await _saveToPrefs(sermon);
      await _updateSermonCounters(sermon);

      print('Sermon download completed successfully: ${sermon.title}');
      ToastUtils.showSuccessToast('Downloaded "${sermon.title}"');
    } catch (e) {
      print('Error downloading sermon: $e');
      ToastUtils.showErrorToast('Failed to download "${sermon.title}"');
      rethrow;
    }
  }

  Future<void> playSermon(Sermon sermon) async {
    try {
      print('Starting sermon playback for: ${sermon.title}');
      
      // Show a rewarded video ad before playing
      print('Attempting to show rewarded video ad before playback');
      bool adShown = false;
      try {
        if (!kIsWeb) {
          adShown = await _adService.showRewardedVideoAd();
          print('Rewarded video ad shown: $adShown');
        }
      } catch (adError) {
        print('Error showing rewarded video ad: $adError');
        // Continue with playback even if ad fails
      }
      
      // Update sermon data
      sermon.clickCount++;

      // Save to local storage and update counters
      await _saveToPrefs(sermon);
      await _updateSermonCounters(sermon);
    } catch (e) {
      print('Error incrementing click count: $e');
      // Don't show error toast to user as this is a background operation
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
      // Update in Firestore
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

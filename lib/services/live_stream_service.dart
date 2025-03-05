import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_stream.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'live_streams';

  String _formatStreamUrl(String url, String platform) {
    if (platform == 'youtube') {
      if (url.contains('youtube.com/watch?v=')) {
        // Convert watch URL to embed URL
        return url.replaceAll('watch?v=', 'embed/');
      } else if (url.contains('youtu.be/')) {
        // Convert short URL to embed URL
        final videoId = url.split('youtu.be/')[1];
        return 'https://www.youtube.com/embed/$videoId';
      } else if (!url.contains('embed')) {
        // Add embed if it's missing
        return url.replaceAll('youtube.com/', 'youtube.com/embed/');
      }
    } else if (platform == 'facebook') {
      if (!url.contains('plugins/video.php')) {
        // Convert direct Facebook URL to embed URL
        return 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(url)}&show_text=false';
      }
    }
    return url;
  }

  // Get current live stream
  Future<LiveStream?> getCurrentLiveStream() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isLive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      // Format the URL before creating the LiveStream object
      data['url'] = _formatStreamUrl(data['url'], data['platform']);
      
      return LiveStream.fromFirestore(doc);
    } catch (e) {
      if (e.toString().contains('failed-precondition') && 
          e.toString().contains('requires an index')) {
        print('Waiting for Firestore index to be built. Please create the index using the link above.');
        // Fallback query without ordering while index is being built
        try {
          final QuerySnapshot snapshot = await _firestore
              .collection(_collection)
              .where('isLive', isEqualTo: true)
              .limit(1)
              .get();

          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          data['url'] = _formatStreamUrl(data['url'], data['platform']);
          return LiveStream.fromFirestore(doc);
        } catch (fallbackError) {
          print('Error in fallback query: $fallbackError');
          return null;
        }
      }
      print('Error getting live stream: $e');
      return null;
    }
  }

  // Get upcoming live streams
  Future<List<LiveStream>> getUpcomingStreams() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('live_streams')
          .where('startTime', isGreaterThan: now)
          .orderBy('startTime')
          .limit(5)
          .get();

      return querySnapshot.docs
          .map((doc) => LiveStream.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting upcoming streams: $e');
      return [];
    }
  }

  // Get past live streams
  Future<List<LiveStream>> getPastStreams() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .orderBy('endTime', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Format the URL before creating the LiveStream object
            data['url'] = _formatStreamUrl(data['url'], data['platform']);
            return LiveStream.fromFirestore(doc);
          })
          .toList();
    } catch (e) {
      print('Error getting past streams: $e');
      return [];
    }
  }
}

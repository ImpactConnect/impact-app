import 'package:cloud_firestore/cloud_firestore.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> incrementVideoViews(String videoId) async {
    try {
      final videoRef = _firestore.collection('videos').doc(videoId);
      
      await videoRef.set({
        'views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error incrementing video views: $e');
    }
  }

  Stream<int> getVideoViews(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) => 
            snapshot.exists ? (snapshot.data()?['views'] ?? 0) : 0);
  }
}

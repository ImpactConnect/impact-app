import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class GalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload image to Firebase Storage and create Firestore document
  Future<bool> uploadImage({
    required File imageFile, 
    required String title, 
    String description = '',
  }) async {
    try {
      // Check user authentication and admin role
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate input
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }

      // Generate unique filename
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('gallery/$fileName');

      // Upload image to Firebase Storage
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create Firestore document
      await _firestore.collection('gallery').add({
        'imageUrl': downloadUrl,
        'title': title,
        'description': description,
        'uploadedBy': user.uid,
        'uploadedAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });

      return true;
    } catch (e) {
      // Log error for debugging
      debugPrint('Gallery Upload Error: $e');
      return false;
    }
  }

  // Delete image from gallery
  Future<bool> deleteImage(String imageId) async {
    try {
      // Check user authentication and admin role
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete Firestore document
      await _firestore.collection('gallery').doc(imageId).delete();

      return true;
    } catch (e) {
      debugPrint('Gallery Delete Error: $e');
      return false;
    }
  }

  // Like an image
  Future<bool> likeImage(String imageId) async {
    try {
      // Check user authentication
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Increment likes
      await _firestore.collection('gallery').doc(imageId).update({
        'likes': FieldValue.increment(1)
      });

      return true;
    } catch (e) {
      debugPrint('Gallery Like Error: $e');
      return false;
    }
  }

  // Stream of gallery images
  Stream<QuerySnapshot> getGalleryImages() {
    return _firestore
        .collection('gallery')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }
}

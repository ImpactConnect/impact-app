import 'package:cloud_firestore/cloud_firestore.dart';

class AppUpdate {
  final String title;
  final String message;
  final String version;
  final String downloadUrl;
  final bool isActive;
  final DateTime createdAt;

  AppUpdate({
    required this.title,
    required this.message,
    required this.version,
    required this.downloadUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory AppUpdate.fromMap(Map<String, dynamic> map) {
    return AppUpdate(
      title: map['title'] ?? 'New Update Available',
      message: map['message'] ?? 'Please update to the latest version for new features and bug fixes.',
      version: map['version'] ?? '1.0.0',
      downloadUrl: map['downloadUrl'] ?? 'https://example.com',
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'version': version,
      'downloadUrl': downloadUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

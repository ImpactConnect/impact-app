import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update.dart';

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Checks if there's an active app update notification
  Future<AppUpdate?> checkForUpdates() async {
    try {
      final snapshot = await _firestore.collection('app_updates').doc('latest').get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['isActive'] == true) {
          return AppUpdate.fromMap(data);
        }
      }
      
      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }
  
  /// Opens the URL for downloading the new app version
  Future<bool> launchUpdateUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
      return false;
    }
  }
}

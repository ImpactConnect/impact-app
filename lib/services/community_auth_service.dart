import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_user.dart';

class CommunityAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userIdKey = 'community_user_id';
  static const String _usernameKey = 'community_username';
  static const String _displayNameKey = 'community_display_name';
  static const String _memberIdKey = 'community_member_id';
  static const String _roleKey = 'community_role';

  Future<CommunityUser?> signIn(String username, String password) async {
    try {
      // Query to find user with matching username
      final querySnapshot = await _firestore
          .collection('community_users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('User not found: $username');
        return null;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Simple password check (in real-world, use proper encryption)
      if (userData['password'] != password) {
        print('Invalid password for user: $username');
        return null;
      }

      // Create CommunityUser object
      final CommunityUser user = CommunityUser.fromFirestore(userDoc);

      // Save user details to SharedPreferences
      await _saveUserToDevice(user);

      // Update last login
      await userDoc.reference
          .update({'last_login': FieldValue.serverTimestamp()});

      return user;
    } catch (e) {
      print('Login error for user $username: $e');
      return null;
    }
  }

  Future<void> _saveUserToDevice(CommunityUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_displayNameKey, user.displayName);
    await prefs.setString(_memberIdKey, user.memberId);
    await prefs.setString(_roleKey, user.role);
  }

  Future<CommunityUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is logged in
    final userId = prefs.getString(_userIdKey);
    if (userId == null) return null;

    // Retrieve user details from SharedPreferences
    return CommunityUser(
      id: userId,
      username: prefs.getString(_usernameKey) ?? '',
      displayName: prefs.getString(_displayNameKey) ?? '',
      memberId: prefs.getString(_memberIdKey) ?? '',
      role: prefs.getString(_roleKey) ?? 'member',
    );
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_memberIdKey);
    await prefs.remove(_roleKey);
  }

  Future<void> generateMockUsers() async {
    try {
      // List of mock users
      final List<Map<String, dynamic>> mockUsers = [
        {
          'username': 'mock_user_1',
          'display_name': 'John Doe',
          'member_id': 'member_001',
          'role': 'member',
          'account_status': 'active',
          'password': 'password123', // Add password for login
          'last_login': null,
        },
        {
          'username': 'mock_user_2',
          'display_name': 'Jane Smith',
          'member_id': 'member_002',
          'role': 'member',
          'account_status': 'active',
          'password': 'password456',
          'last_login': null,
        },
        {
          'username': 'admin_user',
          'display_name': 'Church Admin',
          'member_id': 'admin_001',
          'role': 'admin',
          'account_status': 'active',
          'password': 'adminpass',
          'last_login': null,
        }
      ];

      // Batch write to Firestore
      final WriteBatch batch = _firestore.batch();

      for (var userData in mockUsers) {
        final docRef =
            _firestore.collection('community_users').doc(userData['username']);
        batch.set(docRef, userData);
      }

      // Commit the batch
      await batch.commit();
      print('Mock users generated successfully');
    } catch (e) {
      print('Error generating mock users: $e');
    }
  }

  // Optional: Method to clear mock users
  Future<void> clearMockUsers() async {
    try {
      final mockUsernames = ['mock_user_1', 'mock_user_2', 'admin_user'];

      final WriteBatch batch = _firestore.batch();

      for (var username in mockUsernames) {
        final docRef = _firestore.collection('community_users').doc(username);
        batch.delete(docRef);
      }

      await batch.commit();
      print('Mock users cleared successfully');
    } catch (e) {
      print('Error clearing mock users: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityUser {
  CommunityUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.memberId,
    this.role = 'member',
    this.accountStatus = 'active',
    this.lastLogin,
  });

  // Convert Firestore document to CommunityUser object
  factory CommunityUser.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityUser(
      id: doc.id,
      username: data['username'] ?? '',
      displayName: data['display_name'] ?? '',
      memberId: data['member_id'] ?? '',
      role: data['role'] ?? 'member',
      accountStatus: data['account_status'] ?? 'active',
      lastLogin: data['last_login'],
    );
  }
  final String id;
  final String username;
  final String displayName;
  final String memberId;
  final String role;
  final String accountStatus;
  final Timestamp? lastLogin;

  // Convert CommunityUser to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'display_name': displayName,
      'member_id': memberId,
      'role': role,
      'account_status': accountStatus,
      'last_login': lastLogin ?? FieldValue.serverTimestamp(),
    };
  }
}
